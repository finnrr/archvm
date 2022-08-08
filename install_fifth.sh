# config 
user_name=wrk


# paru
sed -i "s/^#BottomUp$/BottomUp/" /home/$user_name/.config/paru/paru.conf


# zpresto
git clone --recursive https://github.com/sorin-ionescu/prezto.git $ZDOTDIR/.zprezto

setopt EXTENDED_GLOB
for rcfile in "${ZDOTDIR:-$HOME}"/.zprezto/runcoms/^README.md(.N); do
  ln -s "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile:t}"
done

echo 'source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"' >> /home/$user_name/.config/zsh/.zshrc
echo "autoload -Uz promptinit" >> /home/$user_name/.config/zsh/.zshrc
echo "promptinit" >> /home/$user_name/.config/zsh/.zshrc
echo "prompt damoekri" >> /home/$user_name/.config/zsh/.zshrc


# fonts
cat> /home/$user_name/.config/fontconfig/fonts.conf <<EOF
<?xml version='1.0'?>
<!DOCTYPE fontconfig SYSTEM 'fonts.dtd'>
<fontconfig>

 <alias>
  <family>sans-serif</family>
  <prefer>
   <family>Noto Sans Cond</family>
  </prefer>
 </alias>

 <alias>
  <family>serif</family>
  <prefer>
   <family>Noto Serif</family>
  </prefer>
 </alias>

 <alias>
  <family>monospace</family>
  <prefer>
   <family>Noto Sans Mono</family>
  </prefer>
 </alias>

</fontconfig>
EOF


# if [[ -z "$BROWSER" && "$OSTYPE" == darwin* ]]; then
#   export BROWSER='open'
# fi


# # Language
# #

# if [[ -z "$LANG" ]]; then
#   export LANG='en_US.UTF-8'
# fi

# #
# # Paths
# #

# # Ensure path arrays do not contain duplicates.
# typeset -gU cdpath fpath mailpath path

# # Set the list of directories that cd searches.
# # cdpath=(
# #   $cdpath
# # )

# # Set the list of directories that Zsh searches for programs.
# path=(
#   $HOME/{,s}bin(N)
#   /opt/{homebrew,local}/{,s}bin(N)
#   /usr/local/{,s}bin(N)
#   $path
# )

# #
# # Less
# #

# # Set the default Less options.
# # Mouse-wheel scrolling has been disabled by -X (disable screen clearing).   
# # Remove -X to enable it.
# if [[ -z "$LESS" ]]; then
#   export LESS='-g -i -M -R -S -w -X -z-4'
# fi

# # Set the Less input preprocessor.
# # Try both `lesspipe` and `lesspipe.sh` as either might exist on a system.   
# if [[ -z "$LESSOPEN" ]] && (( $#commands[(i)lesspipe(|.sh)] )); then
#   export LESSOPEN="| /usr/bin/env $commands[(i)lesspipe(|.sh)] %s 2>&-"      
# fi


