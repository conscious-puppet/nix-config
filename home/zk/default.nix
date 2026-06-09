{ pkgs, ... }: {
  programs.zk = {
    enable = true;
    settings = {
      notebook.dir = "~/notes";
      note = {
        language = "en";
        default-title = "Untitled";
        filename = "{{id}}-{{slug title}}";
        extension = "md";
        template = ./default.md;
        id-charset = "alphanum";
        id-length = 4;
        id-case = "lower";
      };
      group.journal = {
        paths = [ "journal/" ];
        note.filename = "{{format-date now}}";
        note.template = ./journal.md;
      };

      tool.shell = "${pkgs.zsh}/bin/zsh";
      extra.author = "puppet";
      alias = {
        n = "zk new --no-input \"$ZK_NOTEBOOK_DIR\" -t \"$*\"";
        j = "zk new -g journal \"$ZK_NOTEBOOK_DIR/journal\"";
        ls = "zk list -i";
        e = "zk edit -i";
        edlast = "zk edit --limit 1 --sort modified- $@";
      };
    };
  };
}
