# Evidence Manifest - Project 05

| File | Stage | What it proves |
|---|---|---|
| `01-Baseline-Topology.png` | Baseline | Complete HQ, Branch, ISP, and public-server layout |
| `02-HQ-Control-Public-Success.png` | Before fix / control | Public server and HQ Internet path are operational |
| `03-Before-Branch-Endpoint-Gateway.png` | Before fix | Branch endpoint addressing and local gateway are correct |
| `04-Before-Internal-Success-Public-Failure.png` | Before fix | OSPF/internal access works while the public flow fails |
| `05-Branch-OSPF-Default-Route.png` | Before fix | Branch has an OSPF external default route to HQ |
| `06-HQ-Public-Reachability.png` | Before fix | HQ can reach the public server across the ISP segment |
| `07-Before-NAT-ACL-Evidence.png` | Root-cause evidence | No Branch translation exists and Branch is absent from the NAT ACL |
| `08-Fix-NAT-ACL.png` | Corrective change | Branch subnet added to `NAT_INSIDE` |
| `09-After-Branch-Ping.png` | After fix | Original public-server ping succeeds |
| `10-After-PAT-Translation.png` | After fix | Branch inside-local address is translated by PAT |
| `11-After-HTTP-Access.png` | After fix | HTTP service is restored from Branch |

