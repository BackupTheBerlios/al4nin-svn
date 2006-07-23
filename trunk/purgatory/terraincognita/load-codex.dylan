module: terra-incognita
synopsis: ICFP 2006 contest submission
author: Seth Taylor, heisenbug
copyright: © 2006 terraincognita team

define function load-codex(fn :: <string>) => (scroll :: <scroll>)
  let codex = make(<scroll>, size: /* 586740 */ 3975481);
  let at = 0;
  block (return)
    with-open-file(fs = fn, element-type: <byte-character>)
      while (#t)
        let obj :: false-or(<byte-character>) = read-element(fs, on-end-of-stream: #f);
        unless (obj) return(codex) end;
        let value :: <integer> = as(<integer>, obj);
        let obj :: false-or(<byte-character>) = read-element(fs, on-end-of-stream: #f);
        unless (obj) return(codex) end;
        let value :: <integer> = ash(value, 8) + as(<integer>, obj);
        let obj :: false-or(<byte-character>) = read-element(fs, on-end-of-stream: #f);
        unless (obj) return(codex) end;
        let value :: <integer> = ash(value, 8) + as(<integer>, obj);
        let obj :: false-or(<byte-character>) = read-element(fs, on-end-of-stream: #f);
        unless (obj) return(codex) end;
        let value :: <integer> = ash(value, 8) + as(<integer>, obj);
        codex[at] := value;
        at := at + 1;
      end while;
    end with-open-file;
  end block;
end function load-codex;


