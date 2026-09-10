if status is-interactive
    fish_add_path ~/.local/bin

    if type -q starship
        starship init fish | source
    end
end
