# Disable Fish Welcome Message
set fish_greeting

# Set FZF theme to Neofusion
set -Ux FZF_DEFAULT_OPTS "\
--color=bg+:#031B26,bg:#06101e,spinner:#fd5e3a,hl:#e2d9c5 \
--color=fg:#08435E,header:#e2d9c5,info:#35b5ff,pointer:#fa7a61 \
--color=marker:#fd5e3a,fg+:#66def9,prompt:#35b5ff,hl+:#fd5e3a"

if status is-interactive
    # Commands to run in interactive sessions can go here
    starship init fish | source
    zoxide init fish | source
    set -x ASPNETCORE_ENVIRONMENT Development
    set -x DOTNET_ROOT /usr/share/dotnet
    set -x FUNCTIONS_CORE_TOOLS_TELEMETRY_OPTOUT 1
end
set -gx VOLTA_HOME "$HOME/.volta"
set -gx PATH "$VOLTA_HOME/bin" $PATH
