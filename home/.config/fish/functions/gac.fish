function gac
  git add .
  if test (count $argv) -eq 0
    git commit -m "automated dev commit"
  else
    git commit -m "$argv"
  end
end
