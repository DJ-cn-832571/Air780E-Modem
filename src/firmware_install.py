"""Explicit-model, single-device installer with verified official downloads."""
import fcntl, os, select, subprocess, sys, time
from pathlib import Path
import assets
from usb_discovery import devices
def require_model(model):
    if model!='Air780EHV_A11': raise RuntimeError('仅支持手动确认型号 Air780EHV_A11，禁止猜测型号烧录。')
def single_device():
    found=devices()
    if len(found)!=1: raise RuntimeError('请只接入一台受支持设备；未发现或发现多台设备，拒绝烧录。')
    return found[0]
def command(tool,args,timeout=600):
    process=subprocess.Popen([str(tool)]+args,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    deadline=time.monotonic()+timeout
    try:
        while True:
            ready,_,_=select.select([process.stdout],[],[],.5)
            if ready:
                chunk=os.read(process.stdout.fileno(),65536)
                if not chunk: break
                print(chunk.decode('utf8','replace'),end='',flush=True)
            if time.monotonic()>deadline: raise RuntimeError('烧录工具超时，请保留日志。')
        if process.wait(): raise RuntimeError('烧录工具失败，请保留日志；勿切换其他型号固件。')
    finally:
        if process.poll() is None: process.terminate(); process.wait(timeout=10)
def boot_port(tool):
    device=single_device()
    if device['vendor']==0x19d1:
        ports=[p for i,p in device['ports'] if i==3]
        if len(ports)!=1: raise RuntimeError('无法安全识别 SOC 控制口，已拒绝进入烧录模式。')
        command(tool,['device','boot','--chip','ec718','--port',ports[0]],30)
    deadline=time.monotonic()+35
    while time.monotonic()<deadline:
        found=devices()
        if len(found)>1: raise RuntimeError('出现多台设备，已取消。')
        if len(found)==1 and found[0]['vendor']==0x17d1:
            ports=[p for i,p in found[0]['ports'] if os.path.exists(p)]
            if len(ports)==1: return ports[0]
        time.sleep(.5)
    raise RuntimeError('未安全识别下载口，请重插后重试；不要随意短接引脚。')
def main(model):
    require_model(model)
    single_device()
    lua=assets.ROOT/'firmware/lua'
    if not all((lua/name).is_file() for name in ('main.lua','sys.lua','sysplus.lua')): raise RuntimeError('应用内 Lua 文件不完整。')
    store=assets.CACHE.parent
    store.mkdir(parents=True,exist_ok=True,mode=0o700)
    with (store/'device.lock').open('a') as lock:
        try: fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
        except BlockingIOError: raise RuntimeError('其他设备操作正在执行。')
        core,tool=assets.prepare()
        print('即将覆盖 Air780EHV_A11 固件，请勿拔线。',flush=True)
        command(tool,['flash','run','--soc',str(core),'--port',boot_port(tool),'--script',str(lua)])
    time.sleep(5)
    entry=[sys.executable] if getattr(sys,'frozen',False) else [sys.executable,str(Path(__file__).with_name('backend_entry.py'))]
    for attempt in range(3):
        result=subprocess.run(entry+['status'],capture_output=True,text=True,timeout=45)
        if result.returncode==0: break
        time.sleep(3)
    print(result.stdout+result.stderr,flush=True)
    if result.returncode: raise RuntimeError('写入完成但协议验证失败，请重插后查看设备状态。')
    print('固件与设备协议验证成功，请点击启动上网。',flush=True)

