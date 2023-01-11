#/bin/python3
import os

# Create a function that will apply a command to all files and all subfiles that have a .cairo extension
def apply_command_to_cairo_files():
    for root, dirs, files in os.walk('./lib'):
        for file in files:
            if file.endswith('.cairo'):
                print('Applying command to ' + os.path.join(root, file))
                os.system('npx cairo-docgen' + ' ' + os.path.join(root, file) + ' ' + 'docs')

apply_command_to_cairo_files()