"""Audit a source release archive; no user data is opened or deleted."""
import sys, zipfile
def audit(path):
    blocked=('.sqlite','.soc','.p12','.pem','ed25519','__pycache__','.build-venv','email.json','mail_retry.json')
    secrets=tuple(''.join(parts).encode() for parts in (
        ('/Users/', 'cailiwen'), ('18650', '819999'), ('18695', '627679'),
        ('R5CT', '12KS72R'), ('-----BEGIN ', 'OPENSSH PRIVATE KEY-----'),
        ('-----BEGIN ', 'PRIVATE KEY-----')))
    with zipfile.ZipFile(path) as archive:
        for name in archive.namelist():
            if any(part in name for part in blocked):raise RuntimeError('禁止发布的数据文件：'+name)
            if any(value in archive.read(name) for value in secrets):raise RuntimeError('发现私人信息或私钥：'+name)
    print('源码发布审计通过；制作方公开邮箱是允许的品牌信息。')
if __name__=='__main__':audit(sys.argv[1])
