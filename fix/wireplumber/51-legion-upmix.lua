alsa_monitor.rules = alsa_monitor.rules or {}

-- Desactiva el mixer hardware de la tarjeta sof-hda-dsp: el volumen se aplica
-- por software a los 4 canales (tweeters + woofers AW88399) por igual.
-- Los controles ALSA quedan fijos en su baseline de 0dB (Speaker 87, Bass on).
table.insert(alsa_monitor.rules, {
    matches = {
        {
            { "device.name", "matches", "alsa_card.*skl_hda_dsp_generic*" },
        },
    },
    apply_properties = {
        ["api.alsa.soft-mixer"] = true,
    }
})

table.insert(alsa_monitor.rules, {
    matches = {
        {
            { "node.name", "matches", "alsa_output.*sofhdadsp*" },
        },
    },
    apply_properties = {
        ["audio.channels"] = 4,
        ["audio.position"] = "FL,FR,RL,RR",
        ["channelmix.upmix"] = true,
        ["channelmix.upmix-method"] = "duplicate",
        ["channelmix.lock-channels"] = true,
        ["channelmix.lfe-cutoff"] = 150,
        ["channelmix.fc-cutoff"] = 12000,
    }
})
