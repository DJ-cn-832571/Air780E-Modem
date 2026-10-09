"""Opt-in SMTP forwarding. Password arrives only via anonymous stdin pipe."""
import fcntl, json, os, re, smtplib, ssl, subprocess, time, uuid
from email.message import EmailMessage
from email.utils import formatdate
import sms_store

def config_path(store): return store/'email.json'
def load(store):
    path=config_path(store)
    return json.loads(path.read_text()) if path.exists() else {'enabled':False,'host':'','port':465,'tls':'SSL','username':'','sender':'','recipients':[],'after_rowid':0}
def address(value):
    value=value.strip()
    if not re.fullmatch(r'[^\s@<>;,\r\n]+@[^\s@<>;,\r\n]+\.[^\s@<>;,\r\n]+',value): raise ValueError('邮箱地址格式错误')
    return value
def validate(value):
    result={'enabled':bool(value.get('enabled')), 'host':str(value.get('host','')).strip(),
            'port':int(value.get('port',465)), 'tls':value.get('tls','SSL'),
            'username':str(value.get('username','')).strip(), 'sender':str(value.get('sender','')).strip(),
            'recipients':[address(str(v)) for v in value.get('recipients',[]) if str(v).strip()]}
    result['recipients']=list(dict.fromkeys(result['recipients']))
    if len(result['recipients'])>3: raise ValueError('最多设置三个收件邮箱')
    if result['tls'] not in ('SSL','STARTTLS') or not 1<=result['port']<=65535: raise ValueError('仅支持验证证书的 SSL 或 STARTTLS')
    if result['enabled']:
        if not result['host'] or any(c.isspace() for c in result['host']) or '\x00' in result['host']: raise ValueError('请填写 SMTP 主机名')
        if not result['username'] or not result['recipients']: raise ValueError('请填写 SMTP 用户名和至少一个收件邮箱')
        result['sender']=address(result['sender'])
    elif result['sender']: result['sender']=address(result['sender'])
    return result
def save(store,value):
    value=validate(value)
    old=load(store)
    with sms_store.connect(store) as db:
        maximum=db.execute('SELECT COALESCE(MAX(rowid),0) FROM inbox').fetchone()[0]
    # Enabling or changing recipients never silently forwards historical SMS.
    value['after_rowid']=maximum if not old.get('enabled') or old.get('recipients')!=value['recipients'] else old.get('after_rowid',maximum)
    store.mkdir(parents=True,exist_ok=True,mode=0o700)
    path=config_path(store); temp=store/'email.json.tmp'
    fd=os.open(temp,os.O_WRONLY|os.O_CREAT|os.O_TRUNC,0o600)
    with os.fdopen(fd,'w') as stream: json.dump(value,stream,ensure_ascii=False)
    os.replace(temp,path)
    (store/'mail_retry.json').unlink(missing_ok=True)
    return value
def tls_context():
    context=ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
    roots=subprocess.check_output(['/usr/bin/security','find-certificate','-a','-p','/System/Library/Keychains/SystemRootCertificates.keychain'],timeout=15).decode()
    context.load_verify_locations(cadata=roots)
    return context
def session(config,password):
    if not password: raise ValueError('钥匙串中未保存 SMTP 密码或授权码')
    context=tls_context()
    client=None
    try:
        if config['tls']=='SSL': client=smtplib.SMTP_SSL(config['host'],config['port'],timeout=15,context=context)
        else:
            client=smtplib.SMTP(config['host'],config['port'],timeout=15)
            client.ehlo(); client.starttls(context=context); client.ehlo()
        client.login(config['username'],password)
        return client
    except Exception:
        if client is not None: client.close()
        raise
def test_connection(store,password):
    config=validate(load(store))
    if not config['enabled']: raise ValueError('请先启用并保存邮件转发设置')
    client=session(config,password)
    try: client.noop()
    finally: client.close()
    return 'SMTP 加密连接与登录成功；没有发送测试邮件。'
def forward(store,password):
    config=load(store)
    if not config.get('enabled'): return '邮件转发：未启用'
    config=validate(config)|{'after_rowid':config.get('after_rowid',0)}
    store.mkdir(parents=True,exist_ok=True,mode=0o700)
    with (store/'email.lock').open('a') as lock:
        try: fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
        except BlockingIOError: return '邮件转发：其他任务正在执行'
        with sms_store.connect(store) as db:
            db.execute('CREATE TABLE IF NOT EXISTS mail_delivery (sms_id TEXT, recipient TEXT, state TEXT, detail TEXT, PRIMARY KEY(sms_id,recipient))')
            # Interrupted sends cannot be presumed undelivered; no automatic resend.
            db.execute("UPDATE mail_delivery SET state='unknown',detail='上次转发中断，不能判断是否已送达' WHERE state='sending'")
            rows=db.execute('SELECT rowid,* FROM inbox WHERE rowid>? AND deleted=0 ORDER BY rowid',(config['after_rowid'],)).fetchall()
            pending=[(dict(row),target) for row in rows for target in config['recipients'] if not db.execute('SELECT 1 FROM mail_delivery WHERE sms_id=? AND recipient=?',(row['id'],target)).fetchone()][:15]
        if not pending:
            with sms_store.connect(store) as db:
                count=db.execute("SELECT COUNT(*) FROM mail_delivery WHERE state IN ('failed','unknown')").fetchone()[0]
            return '邮件转发：已同步'+('；有 '+str(count)+' 项失败或结果未知，请查看转发记录' if count else '')
        # Connect/authenticate before marking items; connection errors can retry safely.
        retry_path=store/'mail_retry.json'
        retry=json.loads(retry_path.read_text()) if retry_path.exists() else {}
        if retry.get('blocked'): return '邮件认证失败，已暂停自动尝试；请修正密码或 SMTP 设置并重新保存。'
        if retry.get('next_attempt',0)>time.time(): return '邮件连接失败，等待退避重试；请检查网络与 SMTP 设置。'
        try: client=session(config,password)
        except Exception as error:
            attempts=min(int(retry.get('attempts',0))+1,6)
            state={'attempts':attempts,'next_attempt':time.time()+min(60*2**(attempts-1),900),'blocked':isinstance(error,smtplib.SMTPAuthenticationError)}
            fd=os.open(retry_path,os.O_WRONLY|os.O_CREAT|os.O_TRUNC,0o600)
            with os.fdopen(fd,'w') as stream: json.dump(state,stream)
            if state['blocked']: raise RuntimeError('SMTP 认证失败，已暂停自动尝试，请修正设置并保存。') from None
            raise RuntimeError('SMTP 连接或 TLS 登录失败，将退避重试，请检查网络和服务器配置。') from None
        retry_path.unlink(missing_ok=True)
        accepted=0
        try:
            for row,target in pending:
                with sms_store.connect(store) as db:
                    db.execute("INSERT INTO mail_delivery VALUES (?,?,'sending','')",(row['id'],target))
                mail=EmailMessage()
                mail['From']=config['sender']; mail['To']=target
                mail['Subject']='USB 短信转发'
                mail['Date']=formatdate(localtime=True)
                mail['Message-ID']='<'+str(uuid.uuid5(uuid.NAMESPACE_URL,row['id']+'|'+target))+'@air780e-modem.local>'
                mail.set_content('发送号码：'+row['number']+'\n接收时间：'+row['received']+'\n\n'+row['message'])
                try:
                    refused=client.send_message(mail,from_addr=config['sender'],to_addrs=[target])
                    state,detail=('failed','SMTP 拒绝收件人') if refused else ('sent','邮件服务器已接受，不保证最终送达')
                    if not refused: accepted+=1
                except smtplib.SMTPResponseException as error:
                    state,detail='failed','SMTP 拒绝：'+str(error.smtp_code)
                except Exception:
                    state,detail='unknown','连接中断，不能判断服务器是否已接受；未自动重试'
                with sms_store.connect(store) as db:
                    db.execute('UPDATE mail_delivery SET state=?,detail=? WHERE sms_id=? AND recipient=?',(state,detail,row['id'],target))
                if state=='unknown': break
        finally: client.close()
        return '邮件转发：本轮服务器接受 '+str(accepted)+' 项；详细结果见转发记录'
def history(store):
    with sms_store.connect(store) as db:
        db.execute('CREATE TABLE IF NOT EXISTS mail_delivery (sms_id TEXT, recipient TEXT, state TEXT, detail TEXT, PRIMARY KEY(sms_id,recipient))')
        return [dict(row) for row in db.execute('SELECT * FROM mail_delivery ORDER BY rowid DESC LIMIT 100').fetchall()]
