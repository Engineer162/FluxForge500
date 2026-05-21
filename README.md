
# FluxForge Buck–Boost Power Supply

An open-source buck–boost power supply module targeting heavy duty environments.

## Key Features

- Wide input range: accepts 12–56 V
- Adjustable output: 5–50 V
- Target minimum 10 A output current (500 W min)
- High-efficiency design (target >90%)
- Forced-air cooling (fan) for sustained power
- Non-isolated, single-direction power flow

## Target Electrical Specifications

| Parameter                  | target specifications     |
| -------------------------- | ------------------------- |
| Input voltage range        | 12–56V                    |
| Output voltage range       | 5–50V adjustable          |
| Max output current         | >10A                      |
| Max power                  | 500W                      |
| Efficiency target          | >90%                      |
| Target switching frequency | 80–150kHz                 |
| Cooling                    | fan + heatsink            |
| Isolation?                 | no                        |
| Bidirectional?             | no                        |

### Power Stage Components

| Component | Relevant information |
| --- | --- |
| SFG019N100C3 MOSFET | N-channel MOSFET, 100V VDS, 1.5 mΩ typical RDS(on). |
| Broadcom ACPL-355JC-500E gate driver | Isolated gate driver with up to 10A peak output current and UVLO protection. |

## Mechanical / Cooling

- Desktop module enclosure with mounting feet and air vents.
- Forced-air cooling using a system fan that blows through enclosure.

## Safety and Notes

- Non-isolated design — earth/referenced outputs, suitable for applications where isolation is not required.
- Do NOT block coolong vents, doing so may lead to an unplanned smoke show.