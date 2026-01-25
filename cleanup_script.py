import os

path = r'c:\Users\pc\Desktop\talib_ilm-main\lib\features\quran\presentation\quran_reading_page.dart'

try:
    with open(path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    new_lines = []
    skip = False
    
    for line in lines:
        # Remove unused import
        if "import '../data/quran_api_service.dart';" in line:
            continue
            
        # Detect start of duplicate block
        if 'Convert raw page data to Ayah objects for _buildMushafSpans' in line:
            skip = True
            
        # Detect end of duplicate block (start of next function)
        if '_buildFooterIconButton' in line and skip:
            skip = False
            new_lines.append('\n') # Ensure spacing
            
        if not skip:
            new_lines.append(line)

    with open(path, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
        
    print("Successfully cleaned up the file.")

except Exception as e:
    print(f"Error: {e}")
