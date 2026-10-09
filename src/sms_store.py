"""Local SMS history with recoverable deletion and durable send outcomes."""
import re
import sqlite3
import os
from datetime import datetime
from contextlib import contextmanager

def _connect(store):
    store.mkdir(parents=True,exist_ok=True,mode=0o700)
    path=store/'inbox.sqlite3'
    db=sqlite3.connect(path,timeout=10)
    db.row_factory=sqlite3.Row
    db.execute('CREATE TABLE IF NOT EXISTS inbox (id TEXT PRIMARY KEY, number TEXT, message TEXT, received TEXT)')
    if 'deleted' not in [r[1] for r in db.execute('PRAGMA table_info(inbox)')]:
        db.execute('ALTER TABLE inbox ADD COLUMN deleted INTEGER NOT NULL DEFAULT 0')
    db.execute('CREATE TABLE IF NOT EXISTS outbox (id TEXT PRIMARY KEY, number TEXT, message TEXT, received TEXT, state TEXT, error TEXT)')
    db.execute('CREATE TABLE IF NOT EXISTS purged_sms (id TEXT PRIMARY KEY)')
    db.execute('CREATE TABLE IF NOT EXISTS sms_sequence (singleton INTEGER PRIMARY KEY CHECK(singleton=1), last_rowid INTEGER NOT NULL)')
    db.execute('INSERT OR IGNORE INTO sms_sequence VALUES (1,0)')
    db.execute('UPDATE sms_sequence SET last_rowid=MAX(last_rowid,(SELECT COALESCE(MAX(rowid),0) FROM inbox)) WHERE singleton=1')
    db.commit(); os.chmod(path,0o600)
    return db

@contextmanager
def connect(store):
    db = _connect(store)
    try:
        with db:
            yield db
    finally:
        db.close()

def normalize_number(number):
    number=re.sub(r'[\s()\-]','',number)
    if number.startswith('00'): number='+'+number[2:]
    if re.fullmatch(r'1[3-9]\d{9}',number): number='+86'+number
    elif re.fullmatch(r'861[3-9]\d{9}',number): number='+'+number
    if not re.fullmatch(r'\+?[0-9]{3,20}',number): raise ValueError('号码格式不正确；中国手机号可填 11 位，国际号码请含 + 国家代码。')
    return number

def save(store,frame):
    if frame.get('event')!='sms_received': return
    with connect(store) as db:
        if db.execute('SELECT 1 FROM purged_sms WHERE id=?',(frame['sms_id'],)).fetchone(): return
        if db.execute('SELECT 1 FROM inbox WHERE id=?',(frame['sms_id'],)).fetchone(): return
        db.execute('UPDATE sms_sequence SET last_rowid=last_rowid+1 WHERE singleton=1')
        index=db.execute('SELECT last_rowid FROM sms_sequence WHERE singleton=1').fetchone()[0]
        db.execute('INSERT INTO inbox (rowid,id,number,message,received) VALUES (?,?,?,?,?)',(index,frame['sms_id'],frame.get('number',''),frame.get('message',''),frame.get('received','')))

def rows(store,kind='inbox'):
    with connect(store) as db:
        if kind=='sent': result=db.execute('SELECT * FROM outbox ORDER BY rowid DESC LIMIT 500').fetchall()
        else: result=db.execute('SELECT * FROM inbox WHERE deleted=? ORDER BY rowid DESC LIMIT 500',(1 if kind=='trash' else 0,)).fetchall()
    return [dict(row) for row in result]

def archive(store,ids,restore=False):
    if not ids: raise ValueError('请先选择短信。')
    with connect(store) as db:
        for message_id in ids: db.execute('UPDATE inbox SET deleted=? WHERE id=?',(0 if restore else 1,message_id))

def clear_trash(store):
    with connect(store) as db:
        count=db.execute('SELECT COUNT(*) FROM inbox WHERE deleted=1').fetchone()[0]
        # Keep only opaque IDs so device RAM replay cannot resurrect cleared text.
        db.execute('INSERT OR IGNORE INTO purged_sms SELECT id FROM inbox WHERE deleted=1')
        db.execute('DELETE FROM inbox WHERE deleted=1')
    return count

def clear_all(store):
    with connect(store) as db:
        db.execute('PRAGMA secure_delete=ON')
        count=db.execute('SELECT COUNT(*) FROM inbox').fetchone()[0]
        sent=db.execute('SELECT COUNT(*) FROM outbox').fetchone()[0]
        db.execute('INSERT OR IGNORE INTO purged_sms SELECT id FROM inbox')
        db.execute('DELETE FROM inbox')
        db.execute('DELETE FROM outbox')
        if db.execute("SELECT 1 FROM sqlite_master WHERE type='table' AND name='mail_delivery'").fetchone():
            db.execute('DELETE FROM mail_delivery')
    db=_connect(store)
    try: db.execute('VACUUM')
    finally: db.close()
    return {'receivedRemoved':count,'sentRemoved':sent,'localHistoryCleared':True}

def sending(store,ident,number,message):
    with connect(store) as db:
        db.execute('INSERT INTO outbox VALUES (?,?,?,?,?,?)',(ident,number,message,datetime.now().isoformat(timespec='seconds'),'sending',''))

def outcome(store,ident,state,error=''):
    with connect(store) as db: db.execute('UPDATE outbox SET state=?,error=? WHERE id=?',(state,error,ident))
