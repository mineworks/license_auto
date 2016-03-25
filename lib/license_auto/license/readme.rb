def extract_license_text_from_readme(readme)
  if File.extname(readme['name']) == '.rdoc'
    regular_start = /^==[ *](copying|copy|license){1}:*/i
    regular_end   = /^== /
  elsif File.extname(readme['name']) == '.md'
    regular_start = /^##[ *](copying|copy|license){1}:*/i
    regular_end   = /^## /
  else
    return nil
  end

end