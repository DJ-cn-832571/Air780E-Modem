"""Versioned USB protocol client; unknown vendor firmware is never controlled."""
import atexit, fcntl, glob, json, os, plistlib, re, select, subprocess, sys, time, uuid, sqlite3
from pathlib import Path
from serial_transport import ATSerial
from usb_discovery import candidate_ports
import sms_store
from signal_level import enrich
import network_status
APP = "AIR780E_DEMO"
STORE = Path(os.environ.get("AIR780E_DATA_DIR", str(Path.home() / "Library/Application Support/Air780E Modem")))

class DeviceRejected(RuntimeError):
    pass

class Frames:
    def __init__(self): self.buffer = b""
    def feed(self, data):
        self.buffer += data
        if len(self.buffer)>1048576: self.buffer=b""
        result=[]
        while b"\n" in self.buffer:
            line,self.buffer=self.buffer.split(b"\n",1)
            try:
                value=json.loads(line)
                if isinstance(value,dict): result.append(value)
            except (ValueError,UnicodeError): pass
        return result

def save_sms(frame):
    sms_store.save(STORE,frame)

def receive(serial,seconds):
    parser=Frames(); deadline=time.monotonic()+seconds
    while time.monotonic()<deadline:
        ready,_,_=select.select([serial.fd],[],[],0.2)
        if ready:
            for frame in parser.feed(os.read(serial.fd,4096)):
                if frame.get("app")==APP:
                    save_sms(frame)
                    yield frame

def request(serial,action,**params):
    rid=str(uuid.uuid4())
    payload=(json.dumps(dict(app=APP,protocol=1,action=action,request_id=rid,**params),ensure_ascii=False)+"\n").encode()
    while payload:
        _,writable,_=select.select([],[serial.fd],[],2)
        if not writable: raise RuntimeError("串口写入超时")
        payload=payload[os.write(serial.fd,payload):]
    for frame in receive(serial,65 if action=="send_sms" else 5):
        if frame.get("request_id")==rid:
            if frame.get("event")=="error":
                message=frame.get("message","设备错误")
                explanation={'sms_not_ready':'短信尚未就绪，请等待 SIM 注册网络后重试。','device_busy':'设备正在处理其他操作，请稍后重试。','invalid_sms':'设备拒绝了号码或短信格式。','command_error':'设备端短信处理异常。'}.get(message,message)
                raise DeviceRejected(explanation)
            return frame
    raise RuntimeError("设备未确认命令，不能判定操作成功")

def inbox():
    return "\n\n".join(f"{r['received']}  {r['number']}\n{r['message']}" for r in sms_store.rows(STORE)) or "收件箱暂无短信。"

def usb_interfaces():
    data=subprocess.check_output(['/usr/sbin/ioreg','-r','-c','IOUSBHostDevice','-a','-l'],timeout=10)
    found=set()
    def walk(node, owned=False):
        if isinstance(node,list):
            for item in node: walk(item,owned)
        elif isinstance(node,dict):
            owned=owned or node.get('idVendor')==0x19d1
            name=node.get('BSD Name',node.get('IORegistryEntryName',''))
            if owned and re.fullmatch(r'en\d+',name): found.add(name)
            for child in node.get('IORegistryEntryChildren',[]): walk(child,owned)
    walk(plistlib.loads(data))
    return sorted(found)

def verify_network():
    # Bind requests to the USB descendant; Wi-Fi success must never count.
    for _ in range(10):
        interfaces=usb_interfaces()
        host=network_status.inspect(interfaces)
        if host.get('serviceEnabled') is False:
            return '模块已接受开启 ECM，但 macOS 的 '+host.get('service','AirM2M Compo')+' 网络服务已停用，上网状态为已停止。本程序未擅自重新启用系统服务。'
        if host.get('serviceEnabled') is not True:
            time.sleep(1);continue
        for interface in interfaces:
            ip=subprocess.run(['/usr/sbin/ipconfig','getifaddr',interface],capture_output=True,text=True)
            address=ip.stdout.strip()
            if ip.returncode==0 and address and not address.startswith('169.254.'):
                base=['/usr/bin/curl','--interface',interface,'--connect-timeout','5','--max-time','10','-fsS']
                check=subprocess.run(base+['https://www.apple.com/library/test/success.html'],capture_output=True,text=True)
                dns_note=''
                if check.returncode==6:
                    check=subprocess.run(base+['--doh-url','https://223.5.5.5/dns-query','https://www.apple.com/library/test/success.html'],capture_output=True,text=True)
                    dns_note='\n系统 DNS 未通过，验证使用独立 DoH；未更改系统 DNS。'
                if check.returncode==0 and 'Success' in check.stdout:
                    route=subprocess.run(['/sbin/route','-n','get','default'],capture_output=True,text=True)
                    match=re.search(r'interface:\s*(\S+)',route.stdout)
                    route_note=''
                    if match and match.group(1)!=interface:
                        route_note=f'\n系统默认出口为 {match.group(1)}；其他应用可能仍走原网络/VPN。本程序未修改它。'
                    return f'USB 上网验证成功：{interface}，地址 {address}。HTTPS 请求已绑定此 USB 接口。'+dns_note+route_note
        time.sleep(1)
    return '设备已确认启动，但 USB 接口/DHCP/互联网验证尚未通过，不能判定 Mac 已通过 SIM 上网。'

def main():
    action=sys.argv[1] if len(sys.argv)>1 else "status"
    if action=='activate_network':
        print(json.dumps(network_status.activate(usb_interfaces()),ensure_ascii=False));return
    if action=='clear_all_local':
        if sys.argv[2:]!=['--confirm-permanent']: raise ValueError('清空全部短信需要明确确认')
        print(json.dumps(sms_store.clear_all(STORE),ensure_ascii=False));return
    if action=='system_network':
        try: interfaces=usb_interfaces()
        except (OSError,subprocess.SubprocessError): interfaces=[]
        print(json.dumps(network_status.inspect(interfaces),ensure_ascii=False));return
    if action=='clear_trash':
        if sys.argv[2:]!=['--confirm-permanent']: raise ValueError('永久清空需要明确确认')
        count=sms_store.clear_trash(STORE)
        print('已永久清空已删除列表，共 '+str(count)+' 条；不可恢复。'); return
    if action=="inbox": print(inbox()); return
    if action=='list_json':
        kind=sys.argv[2] if len(sys.argv)>2 else 'inbox'
        print(json.dumps(sms_store.rows(STORE,kind),ensure_ascii=False)); return
    if action=='delete_sent':
        if len(sys.argv)<4 or sys.argv[2]!='--confirm-permanent': raise ValueError('删除发送记录需要明确确认')
        count=sms_store.delete_sent(STORE,sys.argv[3:])
        print('已删除 '+str(count)+' 条本机发送记录；不可恢复，不会撤回短信。');return
    if action in ('delete_sms','restore_sms'):
        sms_store.archive(STORE,sys.argv[2:],restore=action=='restore_sms')
        print('已恢复所选短信。' if action=='restore_sms' else '已移入已删除列表，可恢复。'); return
    STORE.mkdir(parents=True,exist_ok=True,mode=0o700)
    # Hold for the process lifetime so a second app/CLI cannot steal replies.
    lock=(STORE/'device.lock').open('a')
    atexit.register(lock.close)
    try: fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
    except BlockingIOError: raise RuntimeError('另一个设备操作正在执行，请稍后再试。')
    if action=='send_sms':
        if len(sys.argv)!=4 or not 1<=len(sys.argv[3])<=500: raise RuntimeError('短信须为 1–500 字符。')
        if any(ord(c)>65535 or c=='\x00' for c in sys.argv[3]): raise RuntimeError('设备短信编码不支持该表情或特殊字符，请使用普通中文、英文及标点。')
        number=sms_store.normalize_number(sys.argv[2])
    for path in candidate_ports():
        try:
            with ATSerial(path) as serial:
                # Passive identity: do not send guesses to unknown firmware.
                frames=list(receive(serial,2.5))
                if not any(f.get("protocol")==1 for f in frames): continue
                if action in ('poll','sync_json'):
                    frame=request(serial,"inbox")
                    for item in frame.get("messages",[]): save_sms(item)
                    if action=='sync_json':
                        state=next((f for f in reversed(frames) if f.get('event')=='status'),{})
                        print(json.dumps({'messages':sms_store.rows(STORE),'status':enrich(state)},ensure_ascii=False))
                    else: print(inbox())
                    return
                params=dict(number=number,message=sys.argv[3]) if action=="send_sms" else {}
                if action in ('start','stop'):
                    cached=request(serial,'inbox')
                    for item in cached.get('messages',[]): save_sms(item)
                ident=str(uuid.uuid4()) if action=='send_sms' else None
                if ident: sms_store.sending(STORE,ident,number,sys.argv[3])
                try: frame=request(serial,action,**params)
                except Exception as exc:
                    if ident: sms_store.outcome(STORE,ident,'failed' if isinstance(exc,DeviceRejected) else 'unknown',str(exc))
                    raise
                if action=="send_sms":
                    detail=frame.get('detail') or '设备返回发送失败，请检查 SIM 短信业务、余额及运营商限制。'
                    sms_store.outcome(STORE,ident,'accepted' if frame.get('success') else 'failed','' if frame.get('success') else detail)
                    print("短信已被短信中心接受（不等于收件人已收到）。" if frame.get("success") else "短信发送失败："+detail)
                    if not frame.get("success"): sys.exit(1)
                elif action=="start": print(verify_network())
                elif action=="stop": print("设备已接受停止 USB 上网，正在重建 USB 接口；短信会在重新注册网络后恢复。")
                else: print(json.dumps(enrich(frame),ensure_ascii=False,indent=2))
                return
        except OSError: continue
    raise RuntimeError("未收到配套设备协议。可能正在重启、USB 未连接或固件未正常启动。请重试设备状态，仍失败可点击‘安装／修复固件’。本次未发短信；不能仅凭此提示判断设备固件版本。")

if __name__=="__main__":
    try: main()
    except Exception as error: print(str(error)); sys.exit(2)
