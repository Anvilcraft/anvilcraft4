const diameter = 1000000;
const y = 200;

function getRandomCoord() {
    var n = Math.floor(Math.random() * diameter);
    if (Math.round(Math.random())) {
        n *= -1;
    }

    return n;
}

function onRtpExecute(ctx) {
    const player = ctx.source.getPlayerOrException().asKJS();
    const x = getRandomCoord();
    const z = getRandomCoord();

    // add slow falling so the player doesn't immediately die
    player.potionEffects.add(
        "minecraft:slow_falling",
        15 * 20, // 15 seconds
    );

    // teleport
    player.setPositionAndRotation(x, y, z, 0, 0);

    // 1 = success
    return 1;
}

function commandRegistry(ev) {
    const { commands: Commands } = ev;

    ev.register(Commands.literal("rtp").executes(onRtpExecute));
}

onEvent("command.registry", commandRegistry);
