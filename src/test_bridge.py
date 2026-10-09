import json, os, tempfile, unittest
from unittest.mock import patch
import bridge

class ProtocolTests(unittest.TestCase):
    def test_send_failure_preserves_device_detail(self):
        from pathlib import Path
        import sms_store
        with tempfile.TemporaryDirectory() as directory, patch.object(bridge,'STORE',Path(directory)), patch.object(bridge.sys,'argv',['bridge','send_sms','10010','test']), patch.object(bridge,'candidate_ports',return_value=['fake']), patch.object(bridge.glob,'glob',return_value=[]), patch.object(bridge,'ATSerial'), patch.object(bridge,'receive',return_value=iter([dict(app=bridge.APP,protocol=1)])), patch.object(bridge,'request',return_value={'success':False,'detail':'明确的设备错误'}), patch('builtins.print'):
            with self.assertRaises(SystemExit) as error: bridge.main()
            self.assertEqual(error.exception.code,1)
            self.assertEqual(sms_store.rows(Path(directory),'sent')[0]['error'],'明确的设备错误')
    def test_network_switch_saves_device_inbox_first(self):
        from pathlib import Path
        import sms_store
        frame=dict(app=bridge.APP,protocol=1,event='sms_received',sms_id='before-switch',number='10010',message='保留短信',received='now')
        with tempfile.TemporaryDirectory() as directory, patch.object(bridge,'STORE',Path(directory)), patch.object(bridge.sys,'argv',['bridge','start']), patch.object(bridge,'candidate_ports',return_value=['fake']), patch.object(bridge.glob,'glob',return_value=[]), patch.object(bridge,'ATSerial'), patch.object(bridge,'receive',return_value=iter([dict(app=bridge.APP,protocol=1)])), patch.object(bridge,'request',side_effect=[{'messages':[frame]},{'event':'network','usbEnabled':True}]) as request, patch.object(bridge,'verify_network',return_value='test only'), patch('builtins.print'):
            bridge.main()
            self.assertEqual([call.args[1] for call in request.call_args_list],['inbox','start'])
            self.assertEqual(sms_store.rows(Path(directory))[0]['message'],'保留短信')
    def test_delete_and_restore_without_resurrection(self):
        from pathlib import Path
        import sms_store
        with tempfile.TemporaryDirectory() as directory:
            store=Path(directory)
            frame=dict(event='sms_received',sms_id='one',number='10010',message='测试',received='now')
            sms_store.save(store,frame); sms_store.archive(store,['one'])
            sms_store.save(store,frame)
            self.assertEqual(sms_store.rows(store),[])
            self.assertEqual(len(sms_store.rows(store,'trash')),1)
            sms_store.archive(store,['one'],restore=True)
            self.assertEqual(len(sms_store.rows(store)),1)
    def test_number_normalization(self):
        import sms_store
        self.assertEqual(sms_store.normalize_number('138 0013 8000'),'+8613800138000')
        self.assertEqual(sms_store.normalize_number('+1 (415) 555-0123'),'+14155550123')
        self.assertEqual(sms_store.normalize_number('10010'),'10010')
        with self.assertRaises(ValueError): sms_store.normalize_number('abc')
    def test_send_history(self):
        from pathlib import Path
        import sms_store
        with tempfile.TemporaryDirectory() as directory:
            store=Path(directory); sms_store.sending(store,'id','10010','test')
            sms_store.outcome(store,'id','unknown','timeout')
            self.assertEqual(sms_store.rows(store,'sent')[0]['state'],'unknown')
    def test_driverkit_interface_name(self):
        import plistlib
        tree=[{'idVendor':0x19d1,'IORegistryEntryChildren':[{'IORegistryEntryName':'en10'}]}, {'idVendor':1452,'IORegistryEntryChildren':[{'IORegistryEntryName':'en0'}]}]
        with patch.object(bridge.subprocess,'check_output',return_value=plistlib.dumps(tree)):
            self.assertEqual(bridge.usb_interfaces(),['en10'])
    def test_legacy_interface_name(self):
        import plistlib
        tree=[{'idVendor':0x19d1,'IORegistryEntryChildren':[{'BSD Name':'en12'}]}]
        with patch.object(bridge.subprocess,'check_output',return_value=plistlib.dumps(tree)):
            self.assertEqual(bridge.usb_interfaces(),['en12'])
    def test_split_utf8_and_multiple_frames(self):
        p=bridge.Frames()
        wire=(json.dumps({'message':'中文'},ensure_ascii=False)+'\n{}\n').encode()
        frames=[]
        for b in wire: frames.extend(p.feed(bytes([b])))
        self.assertEqual(frames,[{'message':'中文'},{}])
    def test_noise_and_non_object(self):
        self.assertEqual(bridge.Frames().feed(b'noise\n[]\n{}\n'),[{}])
    def test_size_limit(self):
        p=bridge.Frames(); self.assertEqual(p.feed(b'x'*1048577),[])
        self.assertEqual(p.buffer,b'')
    def test_inbox_deduplicates(self):
        from pathlib import Path
        with tempfile.TemporaryDirectory() as directory,patch.object(bridge,'STORE',Path(directory)):
            frame=dict(event='sms_received',sms_id='one',number='10010',message='测试',received='now')
            bridge.save_sms(frame); bridge.save_sms(frame)
            self.assertEqual(bridge.inbox().count('测试'),1)
            self.assertEqual(os.stat(Path(directory)/'inbox.sqlite3').st_mode & 0o777,0o600)
    def test_request_correlation(self):
        class Serial: fd=5
        rid='unique'
        with patch.object(bridge.uuid,'uuid4',return_value=rid),patch.object(bridge.select,'select',return_value=([],[5],[])),patch.object(bridge.os,'write',side_effect=lambda fd,data:len(data)),patch.object(bridge,'receive',return_value=iter([{'request_id':'other'},{'request_id':rid,'event':'status'}])):
            self.assertEqual(bridge.request(Serial(),'status')['request_id'],rid)
    def test_device_error(self):
        class Serial: fd=5
        with patch.object(bridge.uuid,'uuid4',return_value='id'),patch.object(bridge.select,'select',return_value=([],[5],[])),patch.object(bridge.os,'write',side_effect=lambda fd,data:len(data)),patch.object(bridge,'receive',return_value=iter([{'request_id':'id','event':'error','message':'failed'}])):
            with self.assertRaisesRegex(RuntimeError,'failed'): bridge.request(Serial(),'start')

if __name__=='__main__': unittest.main()
