"""Pinned upstream downloads. No proprietary core is redistributed."""
import hashlib, os, subprocess, sys, tarfile
from pathlib import Path
ROOT = Path(sys.executable).resolve().parents[1] if getattr(sys,'frozen',False) else Path(__file__).resolve().parents[1]
CACHE = Path(os.environ.get('AIR780E_DATA_DIR',str(Path.home()/'Library/Application Support/Air780E Modem')))/'assets'
ASSETS = {
 'core.soc': ('https://cdn18.luatos.com/files/Air780EHV/LuatOS_Air780EHV/LuatOS-SoC_V2052_Air780EHV/LuatOS-SoC_V2052_Air780EHV_1.soc','55cb7c2fe6d63caac4811f2ea58ac93ccf4fae678732e2f05903952c6d6e1d5f'),
 'cli.tar.gz': ('https://github.com/wendal/luatos-cli/releases/download/v1.11.0/luatos-cli-aarch64-apple-darwin.tar.gz','115891d78052a2dccd2b574c12635b19dc4a794d66f6b4ed029e264c5af32026')}
def digest(path):
    h=hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda:stream.read(1048576),b''): h.update(block)
    return h.hexdigest()
def fetch(name):
    url,sha=ASSETS[name]
    CACHE.mkdir(parents=True,exist_ok=True,mode=0o700)
    target=CACHE/name
    if target.is_file() and digest(target)==sha: return target
    part=CACHE/(name+'.part')
    try:
        print('正在下载并校验：'+name,flush=True)
        subprocess.run(['/usr/bin/curl','--fail','--location','--proto','=https','--proto-redir','=https','--connect-timeout','20','--max-time','300','--output',str(part),url],check=True)
        if digest(part)!=sha: raise RuntimeError('下载文件 SHA-256 不匹配，拒绝使用。')
        os.replace(part,target)
    finally:
        part.unlink(missing_ok=True)
    return target
def prepare():
    core=fetch('core.soc'); archive=fetch('cli.tar.gz')
    tool=CACHE/'luatos-cli'
    with tarfile.open(archive,'r:gz') as tar:
        members=[m for m in tar.getmembers() if Path(m.name).name=='luatos-cli' and m.isfile()]
        if len(members)!=1: raise RuntimeError('工具压缩包结构不符合预期。')
        stream=tar.extractfile(members[0])
        with tool.open('wb') as output:
            while block:=stream.read(1048576): output.write(block)
    tool.chmod(0o700)
    return core,tool
