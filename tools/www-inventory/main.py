#!/usr/bin/env python3

import os


def create_index_html(folder_path):
    """Create an index.html file for the given folder_path"""
    # Create a list of filenames in the folder
    filenames = os.listdir(folder_path)
    # Generate the HTML content for the file
    html = "<html><head><title>Index of {}</title></head><body><h1>Index of {}</h1>\n<ul>".format(
        folder_path, folder_path
    )
    for filename in filenames:
        # Skip over any hidden files
        if filename.startswith("."):
            continue
        # Generate an HTML link for the file
        link = '<li><a href="{}/{}">{}</a></li>\n'.format(
            folder_path, filename, filename
        )
        html += link
    html += "</ul></body></html>"
    # Write the HTML content to a file named index.html in the folder
    # with open(os.path.join(folder_path, "index.html"), "w") as f:
    #    f.write(html)
    print(html)


# Example usage: create an index.html file for the current directory
create_index_html("../../active")
