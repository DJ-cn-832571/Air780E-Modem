import unittest
from unittest.mock import patch
import network_status as net
class HostNetworkTests(unittest.TestCase):
    order='(*) AirM2M Compo\n(Hardware Port: AirM2M Compo, Device: en10)\n(1) Wi-Fi\n(Hardware Port: Wi-Fi, Device: en1)'
    def test_disabled_order_matches_usb_not_wifi(self):
        self.assertEqual(net.services(self.order)[0],('AirM2M Compo','en10'))
        with patch.object(net,'run',side_effect=[self.order,'Disabled']) as run:
            state=net.inspect(['en10'])
        self.assertFalse(state['serviceEnabled']);self.assertFalse(state['connected']);self.assertEqual(run.call_count,2)
    def test_missing_service_not_active(self):
        with patch.object(net,'run',return_value=self.order):state=net.inspect(['en55'])
        self.assertIsNone(state['serviceEnabled'])
    def test_renamed_service_matches_interface(self):
        with patch.object(net,'run',side_effect=[self.order.replace('(*) AirM2M Compo','(*) Cellular USB'),'Disabled']):state=net.inspect(['en10'])
        self.assertEqual(state['service'],'Cellular USB');self.assertFalse(state['serviceEnabled'])
    def test_query_failure_unknown(self):
        with patch.object(net,'run',side_effect=OSError()):state=net.inspect(['en10'])
        self.assertIsNone(state['serviceEnabled'])
    def test_link_down_not_started(self):
        with patch.object(net,'run',side_effect=[self.order,'Enabled','flags=1<UP>\nstatus: inactive']),patch.object(net.subprocess,'run') as ip:
            ip.return_value.stdout='192.168.10.2'
            state=net.inspect(['en10'])
        self.assertTrue(state['serviceEnabled']);self.assertFalse(state['connected'])
    def test_link_and_ip_required(self):
        for ip,expected in [('192.168.10.2',True),('169.254.1.1',False),('',False)]:
            with patch.object(net,'run',side_effect=[self.order,'Enabled','flags=1<UP,RUNNING>\nstatus: active']),patch.object(net.subprocess,'run') as command:
                command.return_value.stdout=ip
                self.assertEqual(net.inspect(['en10'])['connected'],expected)

