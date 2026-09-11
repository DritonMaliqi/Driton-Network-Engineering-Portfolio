from pathlib import Path
import sys

SRC = Path(__file__).resolve().parents[1] / 'src'
sys.path.insert(0, str(SRC))

from scenario_engine import generate_scenario
from evaluator_engine import evaluate_multi_fault

def test_all_topics_generate():
    topics = ['VLAN','TRUNK','DHCP','OSPF']
    levels = ['Easy','Medium','Hard']
    for topic in topics:
        for level in levels:
            s = generate_scenario('TEST', topic, level, 'CCNA')
            assert s.topic

def test_vlan_hard_multifault():
    s = generate_scenario('TEST','VLAN','Hard','CCNA')
    assert len(s.all_faults()) == 2

def test_ospf_hard_scoring():
    r = evaluate_multi_fault(
        'OSPF Troubleshooting',
        'OSPF uses area 0 on HQ and area 1 on Branch and Branch LAN 192.168.30.0 is not advertised',
        'Configure the WAN link in the same OSPF area and advertise network 192.168.30.0 in OSPF',
        'Hard'
    )
    assert r['total'] == 100
