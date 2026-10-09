import unittest
from usb_discovery import parse_devices
from firmware_install import require_model
class ReleaseTests(unittest.TestCase):
    def test_unrelated_adapter_ignored(self):
        self.assertEqual(parse_devices([{'idVendor':123,'idProduct':1,'IOCalloutDevice':'/dev/cu.other'}]),[])
    def test_interface_ownership(self):
        tree=[{'idVendor':0x19d1,'idProduct':1,'IORegistryEntryChildren':[{'bInterfaceNumber':7,'IORegistryEntryChildren':[{'IOCalloutDevice':'/dev/cu.example'}]}]}]
        self.assertEqual(parse_devices(tree)[0]['ports'],[(7,'/dev/cu.example')])
    def test_model_is_explicit(self):
        for model in ('','Air780E','Air780EHM'):
            with self.assertRaises(RuntimeError): require_model(model)
        require_model('Air780EHV_A11')

