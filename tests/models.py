from model import (And, Array, Edge, Equal, FINAL, First, GreaterEqual, Last, Length, LessEqual,
                   ModularInteger, Node, NotEqual, Number, PDU, RangeInteger, Sub, Value)


def create_ethernet_pdu() -> PDU:
    uint48 = ModularInteger('UINT48', 2**48)
    uint16 = RangeInteger('UINT16', 0, 2**16 - 1, 16)
    payload_array = Array('Payload_Array')

    destination = Node('Destination', uint48)
    source = Node('Source', uint48)
    tpid = Node('TPID', uint16)
    tci = Node('TCI', uint16)
    ether_type = Node('EtherType', uint16)
    payload = Node('Payload', payload_array)

    destination.edges = [Edge(source)]
    source.edges = [Edge(tpid)]
    tpid.edges = [Edge(tci,
                       Equal(Value('TPID'), Number(0x8100))),
                  Edge(ether_type,
                       NotEqual(Value('TPID'), Number(0x8100)),
                       first=First('TPID'))]
    tci.edges = [Edge(ether_type)]
    ether_type.edges = [Edge(payload,
                             LessEqual(Value('EtherType'), Number(1500)),
                             Value('EtherType')),
                        Edge(payload,
                             GreaterEqual(Value('EtherType'), Number(1536)),
                             Sub(Last('Buffer'), Last('EtherType')))]
    payload.edges = [Edge(FINAL,
                          And(GreaterEqual(Length('Payload'), Number(46)),
                              LessEqual(Length('Payload'), Number(1500))))]

    return PDU('Ethernet', destination)


ETHERNET_PDU = create_ethernet_pdu()
