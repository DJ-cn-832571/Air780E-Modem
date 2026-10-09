"""Approximate LTE RSRP indicator; not an operator-defined signal scale."""
def bars(rsrp):
    if isinstance(rsrp,bool) or not isinstance(rsrp,(float,int)) or not -140<=rsrp<=-44: return None
    return 5 if rsrp>=-85 else 4 if rsrp>=-95 else 3 if rsrp>=-105 else 2 if rsrp>=-115 else 1
def enrich(state):
    return dict(state,signalBars=bars(state.get('rsrp')))
