{ lib, pkgs, ... }:
let
  # Every directory under ./skills is a user-wide agent skill. Adding a skill is
  # just dropping a folder with a SKILL.md next to the existing ones.
  skillsSource = ./skills;

  # Claude Code reads ~/.claude/skills, Codex reads ~/.codex/skills.
  targets = [ ".claude/skills" ".codex/skills" ];
in
{
  # Copy rather than symlink: both tools discover skills by walking their
  # directories, and symlinks into the read-only Nix store are not followed
  # reliably by every version. rsync also adopts a pre-existing identical copy
  # without leaving an `.hm-backup` duplicate that would load as a second skill.
  #
  # Only skills listed in ./skills are touched, and `--delete` is scoped to
  # each managed skill's own folder, so unmanaged skills (humanizer, synced,
  # the Codex .system set) are left alone. Local edits to a managed skill are
  # overwritten at the next switch: change the copy in this repository.
  home.activation.installAgentSkills = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for target in ${lib.concatMapStringsSep " " (t: ''"$HOME/${t}"'') targets}; do
      run mkdir -p "$target"
      for skill in ${skillsSource}/*/; do
        [ -f "$skill/SKILL.md" ] || continue
        name="$(basename "$skill")"
        run ${pkgs.rsync}/bin/rsync -a --delete --exclude=__pycache__ \
          --chmod=Du+rwx,Fu+rw "$skill" "$target/$name/"
      done
    done
  '';
}
