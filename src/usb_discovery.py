"""Select ports owned by the known USB device, not unrelated adapters."""
import plistlib
import subprocess
def parse_devices(tree):
    found = []
    def ports(node, interface=None):
        result = []
        if isinstance(node,list):
            for child in node: result.extend(ports(child,interface))
        elif isinstance(node,dict):
            interface=node.get('bInterfaceNumber',interface)
            path=node.get('IOCalloutDevice')
            if isinstance(path,str) and path.startswith('/dev/cu.'): result.append((interface,path))
            result.extend(ports(node.get('IORegistryEntryChildren',[]),interface))
        return result
    def walk(node):
        if isinstance(node,list):
            for child in node: walk(child)
        elif isinstance(node,dict):
            if node.get('idVendor') in (0x19d1,0x17d1) and node.get('idProduct')==1:
                found.append({'vendor':node['idVendor'],'ports':ports(node)})
            else: walk(node.get('IORegistryEntryChildren',[]))
    walk(tree)
    return found
def devices():
    raw=subprocess.check_output(['/usr/sbin/ioreg','-r','-c','IOUSBHostDevice','-a','-l'],timeout=10)
    return parse_devices(plistlib.loads(raw))
def candidate_ports():
    return [p for d in devices() if d['vendor']==0x19d1 for i,p in d['ports'] if i in (6,7)]
