import markdown

with open("README.md", "r", encoding="utf-8") as f:
    text = f.read()
    html = markdown.markdown(text)

with open("README.html", "w", encoding="utf-8") as f:
    f.write(html)
