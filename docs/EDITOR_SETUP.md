# Editor & IDE Setup for Shutter

Shutter's modern architecture benefits greatly from Language Server Protocol (LSP) and static analysis tools. Here are the recommended configurations for various environments.

## 🪟 Cross-Platform Development (Windows & MacOS)
While Shutter is a Linux application, you can perform logic refactoring and development on any OS using **Docker**.
*   **Recommendation:** Use the [**DevContainer**](.devcontainer/devcontainer.json) in VS Code. It provides a pre-configured Linux environment with all dependencies and Perl v5.40.

---

## 💻 Editor Recommendations

### 🟦 Visual Studio Code (Recommended)
1.  **Extension:** [Perl Navigator](https://marketplace.visualstudio.com/items?itemName=bscan.perlnavigator) (High-quality LSP).
2.  **Extension:** [Perl Tidy](https://marketplace.visualstudio.com/items?itemName=rebornix.perl-tidy).
3.  **Config:** The project includes `.perltidyrc` and `.perlcriticrc` which these extensions will detect automatically.

### 🟩 Vim / Neovim
*   **LSP:** Use `nvim-lspconfig` or `CoC` with the `perlnavigator` or `Perl::LanguageServer`.
*   **Tidy:** Add a shortcut to run `perltidy` on save or via command:
    ```vim
    " Format current file
    nnoremap <leader>t :!perltidy -b -pbp %<CR>
    ```

### 🟣 Emacs
*   **Mode:** Use `cperl-mode` (superior to the default `perl-mode`).
*   **LSP:** Use `lsp-mode` with `perl-language-server`.
*   **Flycheck:** Enable `flycheck-perl` to see Perl Critic warnings in real-time.

---

## 🛠️ Global Tooling Tips

### 1. Perl v5.40 Signatures
Ensure your LSP is configured to recognize v5.40 syntax. The `Perl Navigator` handles this well if the `use v5.40;` statement is present in your file.

### 2. Carton Integration
If you are developing locally (not in a container), run your editor from within the `carton` environment to ensure the LSP sees your project dependencies:
```bash
carton exec code .
# or
carton exec nvim
```

### 3. Git Hooks
Running `./bin/setup` installs a pre-commit hook that runs `perltidy`. This ensures code remains consistent regardless of your editor.
