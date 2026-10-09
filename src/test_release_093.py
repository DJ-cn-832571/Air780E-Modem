import tempfile,unittest
from pathlib import Path
from unittest.mock import patch
import network_status as net
import sms_store
class Release093Tests(unittest.TestCase):
    def test_activation_uses_verified_service_and_rechecks(self):
        with patch.object(net,'inspect',side_effect=[{'serviceEnabled':False,'service':'Known USB'}, {'serviceEnabled':True}]),patch.object(net,'run') as run:
            self.assertTrue(net.activate(['en10'])['activationAccepted'])
            run.assert_called_once_with(['/usr/sbin/networksetup','-setnetworkserviceenabled','Known USB','on'])
    def test_activation_never_guesses_unknown_service(self):
        with patch.object(net,'inspect',return_value={'serviceEnabled':None}),patch.object(net,'run') as run:
            with self.assertRaises(RuntimeError):net.activate([])
            run.assert_not_called()
    def test_permission_failure_directs_to_settings(self):
        with patch.object(net,'inspect',return_value={'serviceEnabled':False,'service':'Known USB'}),patch.object(net,'run',side_effect=RuntimeError()):
            with self.assertRaisesRegex(RuntimeError,'系统网络设置'):net.activate(['en10'])
    def test_activation_does_not_claim_success_without_confirmation(self):
        with patch.object(net,'inspect',return_value={'serviceEnabled':False,'service':'Known USB'}),patch.object(net,'run'):
            with self.assertRaises(RuntimeError):net.activate(['en10'])
    def test_clear_all_removes_messages_outbox_and_mail_history(self):
        with tempfile.TemporaryDirectory() as directory:
            store=Path(directory)
            frame=dict(event='sms_received',sms_id='mock-id',number='10010',message='mock body',received='now')
            sms_store.save(store,frame);sms_store.sending(store,'sent','10010','mock')
            with sms_store.connect(store) as db:
                db.execute('CREATE TABLE mail_delivery (sms_id TEXT, recipient TEXT, state TEXT, detail TEXT)')
                db.execute("INSERT INTO mail_delivery VALUES ('mock-id','user@example.com','sent','mock')")
            result=sms_store.clear_all(store)
            self.assertTrue(result['localHistoryCleared'])
            self.assertEqual(sms_store.rows(store),[]);self.assertEqual(sms_store.rows(store,'sent'),[])
            with sms_store.connect(store) as db:self.assertEqual(db.execute('SELECT COUNT(*) FROM mail_delivery').fetchone()[0],0)
            sms_store.save(store,frame);self.assertEqual(sms_store.rows(store),[])
