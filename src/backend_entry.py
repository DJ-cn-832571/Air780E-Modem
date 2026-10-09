"""Standalone GUI backend and developer CLI."""
import json, sys
import bridge
import firmware_install
import email_forward
import platform
def main():
    action=sys.argv[1] if len(sys.argv)>1 else 'status'
    if action=='diagnostics':
        import network_status
        try: interfaces=bridge.usb_interfaces()
        except Exception: interfaces=[]
        state=network_status.inspect(interfaces)
        print(json.dumps({'version':'0.9.6','macOS':platform.mac_ver()[0],'architecture':platform.machine(),'usbInterfaces':interfaces,'systemServiceEnabled':state.get('serviceEnabled'),'linkConnected':state.get('connected'),'containsSMSOrCredentials':False},ensure_ascii=False,indent=2));return
    if action=='email_config':
        print(json.dumps(email_forward.load(bridge.STORE),ensure_ascii=False)); return
    if action in ('email_save','email_validate'):
        config=json.load(sys.stdin)
        result=email_forward.save(bridge.STORE,config) if action=='email_save' else email_forward.validate(config)
        print(json.dumps(result,ensure_ascii=False)); return
    if action=='email_history':
        print(json.dumps(email_forward.history(bridge.STORE),ensure_ascii=False,indent=2)); return
    if action in ('email_forward','email_test'):
        password=json.load(sys.stdin).get('password','')
        try:
            print(email_forward.forward(bridge.STORE,password) if action=='email_forward' else email_forward.test_connection(bridge.STORE,password))
        except Exception as error:
            message=str(error).replace(password,'[已隐藏]') if password else str(error)
            raise RuntimeError('邮件操作失败：'+message) from None
        return
    if len(sys.argv)>1 and sys.argv[1]=='--self-test':
        import sqlite3, ssl
        db=sqlite3.connect(':memory:'); db.execute('select 1'); db.close()
        import assets
        if not (assets.ROOT/'firmware/lua/main.lua').is_file(): raise RuntimeError('配套 Lua 资源缺失')
        print(json.dumps({'backend':'ok','sqlite':'ok','lua':'ok','tls':ssl.OPENSSL_VERSION}))
    elif len(sys.argv)>1 and sys.argv[1]=='install_firmware':
        firmware_install.main(sys.argv[2] if len(sys.argv)==3 else '')
    else: bridge.main()
if __name__=='__main__':
    try: main()
    except Exception as error:
        print('操作失败：'+str(error),flush=True); sys.exit(2)
