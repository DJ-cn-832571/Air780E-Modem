"""Read-only macOS network-service state, matched to the USB-owned interface."""
import ipaddress, re, subprocess, time
def run(args):
    result=subprocess.run(args,capture_output=True,text=True,timeout=8)
    if result.returncode: raise RuntimeError('系统网络查询失败')
    return result.stdout.strip()
def services(text):
    result=[]; name=None
    for line in text.splitlines():
        match=re.match(r'^\((?:\d+|\*)\)\s+(.+)$',line.strip())
        if match: name=match.group(1);continue
        hardware=re.search(r'Hardware Port: (.*), Device: ([^)]+)',line)
        if hardware and name:
            result.append((name,hardware.group(2).strip()));name=None
    return result
def inspect(interfaces):
    state={'checkedAt':time.time(),'serviceEnabled':None,'connected':False,'detail':'等待系统网络确认'}
    try:
        matches=[(name,dev) for name,dev in services(run(['/usr/sbin/networksetup','-listnetworkserviceorder'])) if dev in interfaces]
        if len(matches)!=1:
            state['detail']='未发现唯一匹配的 AirM2M 系统网络服务';return state
        name,dev=matches[0];state.update(service=name,interface=dev)
        enabled=run(['/usr/sbin/networksetup','-getnetworkserviceenabled',name])
        if enabled not in ('Enabled','Disabled'): return state
        state['serviceEnabled']=enabled=='Enabled'
        if not state['serviceEnabled']:
            state['detail']='macOS 已停用 '+name;return state
        link=run(['/sbin/ifconfig',dev])
        ip=subprocess.run(['/usr/sbin/ipconfig','getifaddr',dev],capture_output=True,text=True,timeout=8).stdout.strip()
        try:
            address=ipaddress.ip_address(ip)
            valid=not (address.is_link_local or address.is_unspecified or address.is_loopback)
        except ValueError: valid=False
        up=bool(re.search(r'flags=.*<[^>]*\bUP\b',link))
        active=bool(re.search(r'status:\s*active\b',link))
        state['connected']=up and active and valid
        state['detail']='系统网卡已连接（互联网连通性未验证）' if state['connected'] else '系统服务启用，但网卡未连接或未取得有效地址'
        if valid: state['address']=ip
    except (OSError,subprocess.SubprocessError,RuntimeError):
        state['serviceEnabled']=None;state['detail']='无法读取系统网络状态，不能判断已启动'
    return state

def activate(interfaces):
    state=inspect(interfaces)
    if state.get('serviceEnabled') is None or not state.get('service'):
        raise RuntimeError('不能唯一确认 AirM2M 网卡，请在系统网络设置手工启用。')
    if state['serviceEnabled']:
        return dict(state,activationAccepted=True)
    try:
        run(['/usr/sbin/networksetup','-setnetworkserviceenabled',state['service'],'on'])
    except (OSError,subprocess.SubprocessError,RuntimeError):
        raise RuntimeError('macOS 不允许当前权限启用网卡，请点击打开系统网络设置手工启用。') from None
    updated=inspect(interfaces)
    if updated.get('serviceEnabled') is not True:
        raise RuntimeError('系统尚未确认启用，请打开网络设置检查 AirM2M Compo。')
    return dict(updated,activationAccepted=True)
