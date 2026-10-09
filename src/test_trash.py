import tempfile, unittest
from pathlib import Path
from unittest.mock import patch
import bridge, sms_store
class TrashTests(unittest.TestCase):
    def test_clears_all_not_only_visible_500_and_preserves_other_lists(self):
        with tempfile.TemporaryDirectory() as directory:
            store=Path(directory)
            with sms_store.connect(store) as db:
                db.executemany('INSERT INTO inbox VALUES (?,?,?,?,?)',[(str(i),'10010','example','now',1) for i in range(510)])
                db.execute("INSERT INTO inbox VALUES ('keep','10010','keep','now',0)")
            sms_store.sending(store,'sent','10010','keep sent')
            self.assertEqual(sms_store.clear_trash(store),510)
            self.assertEqual(sms_store.rows(store,'trash'),[])
            self.assertEqual(len(sms_store.rows(store)),1)
            self.assertEqual(len(sms_store.rows(store,'sent')),1)
            self.assertEqual(sms_store.clear_trash(store),0)
    def test_device_replay_cannot_resurrect_purged_sms(self):
        with tempfile.TemporaryDirectory() as directory:
            store=Path(directory); frame=dict(event='sms_received',sms_id='id',number='10010',message='private mock body',received='now')
            sms_store.save(store,frame);sms_store.archive(store,['id']);sms_store.clear_trash(store)
            sms_store.save(store,frame);sms_store.archive(store,['id'],restore=True)
            self.assertEqual(sms_store.rows(store),[])
            with sms_store.connect(store) as db:
                self.assertEqual(db.execute('SELECT * FROM purged_sms').fetchone()['id'],'id')
                self.assertEqual(db.execute('SELECT COUNT(*) FROM inbox').fetchone()[0],0)
    def test_cli_requires_explicit_confirmation(self):
        with tempfile.TemporaryDirectory() as directory,patch.object(bridge,'STORE',Path(directory)),patch.object(bridge.sys,'argv',['backend','clear_trash']):
            with self.assertRaises(ValueError):bridge.main()
    def test_new_sms_keeps_increasing_index_after_emptying(self):
        with tempfile.TemporaryDirectory() as directory:
            store=Path(directory)
            def incoming(ident):sms_store.save(store,dict(event='sms_received',sms_id=ident,number='10010',message='mock',received='now'))
            incoming('first')
            with sms_store.connect(store) as db: previous=db.execute('SELECT MAX(rowid) FROM inbox').fetchone()[0]
            sms_store.archive(store,['first']);sms_store.clear_trash(store);incoming('second')
            with sms_store.connect(store) as db: self.assertGreater(db.execute('SELECT MAX(rowid) FROM inbox').fetchone()[0],previous)
