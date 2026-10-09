import io, tempfile, unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch
import bridge, sms_store

class SentDeletionTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory(); self.addCleanup(self.temp.cleanup)
        self.store=Path(self.temp.name)
        for ident,state in [('a','accepted'),('b','failed'),('c','unknown'),('active','sending')]:
            sms_store.sending(self.store,ident,'10010','mock only')
            sms_store.outcome(self.store,ident,state)
        sms_store.save(self.store,dict(event='sms_received',sms_id='in',number='10010',message='mock inbox',received='now'))
    def test_single_and_batch_only_remove_requested_sent_ids(self):
        self.assertEqual(sms_store.delete_sent(self.store,['a']),1)
        self.assertEqual(sms_store.delete_sent(self.store,['b','c','c','absent']),2)
        self.assertEqual([row['id'] for row in sms_store.rows(self.store,'sent')],['active'])
        self.assertEqual(len(sms_store.rows(self.store)),1)
    def test_active_send_rejects_whole_batch(self):
        with self.assertRaises(ValueError): sms_store.delete_sent(self.store,['a','active'])
        self.assertEqual(len(sms_store.rows(self.store,'sent')),4)
    def test_empty_selection_rejected(self):
        with self.assertRaises(ValueError): sms_store.delete_sent(self.store,[])
    def test_cli_requires_explicit_confirmation(self):
        with patch.object(bridge,'STORE',self.store),patch.object(bridge.sys,'argv',['backend','delete_sent','a']):
            with self.assertRaises(ValueError):bridge.main()
    def test_cli_deletes_without_device_commands(self):
        with patch.object(bridge,'STORE',self.store),patch.object(bridge.sys,'argv',['backend','delete_sent','--confirm-permanent','a']),patch.object(bridge,'candidate_ports',side_effect=AssertionError('must not access device')),redirect_stdout(io.StringIO()):
            bridge.main()
        self.assertEqual(len(sms_store.rows(self.store,'sent')),3)
