# SEOUL MATES — Development status

Status: **playable local alpha**, not a finished release.

## Implemented

- Godot 4.7.2 project with Compatibility renderer and single-threaded Web export preset.
- Original procedural restaurant art, walkable room, collision, character movement, interaction prompts and keyboard/mouse controls.
- Data-driven tteokbokki and ramyeon recipes; inventory, carried ingredients, chopping, heat simulation, circular stirring, plating quality and completed dishes.
- A three-order restaurant shift with a customer who walks from the entrance to a table and exits after service, patience, matching dishes, single payment per order, shared money and a next-day transition.
- Dedicated Godot WebSocket server on port 9090, one development room, authoritative inventory/cooking/payment/positions, snapshots, station control lock and local JSON save of day/money/inventory.
- README, architecture, deployment and issue documentation plus a CI headless-check workflow.

## Verified locally

- Godot headless import and scene startup completed.
- State tests completed a three-order shift, checked inventory use, duplicate serving, save/load and next-day transition.
- A Godot Web debug export completed with threading disabled.
- Firefox WebDriver loaded and rendered the actual exported game canvas; a screenshot was inspected.
- Two separate Firefox windows joined the same local server. Screenshots showed identical order/balance/inventory HUD values and both player avatars. The server logged both peer joins and leaves.
- Two separate headless Godot clients cooked one shared tteokbokki, contributed different ingredients, and saw the same single payment. A duplicate serve did not pay again. A new client joined after both cooks left and saw the completed order and balance. After a server restart, another client saw the saved balance and inventory.

## Not yet implemented or verified

- Browser-driven full cooking/serving, reconnect identity, ten consecutive cooperative orders and production WSS hosting.
- Dynamic room creation and join codes, secure membership, persistence of full layout/progression and transaction log.
- Customer seat selection and path recovery, build mode, furniture placement, audio, touch joystick, iPhone testing, final sprite art and performance profiling.
- Public repository, deployed client, deployed backend or live URL.
