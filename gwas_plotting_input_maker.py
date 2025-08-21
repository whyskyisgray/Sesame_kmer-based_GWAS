import argparse

#sys
parser = argparse.ArgumentParser('usage')
parser.add_argument('-input', help = 'anchored file')
parser.add_argument('-config', help = 'Config file, config file ')
parser.add_argument('-example', action='store_true', help='show config file details')
args = parser.parse_args()

if args.example:
        print('\n\ncw_chr01\t1\tA\tred\t54244566\ncw_chr02\t2\tB\tblack\t34204566\n\ncolor: red, green, blue, etc...\ntype: A(dot), B(triangle), C(square)\n\n')

if not args.input or not args.config:
    parser.error('Both -input and -config are required.')
# Open and read input file
with open(args.input) as input_file:
    contents = list(filter(None, input_file.read().split('\n')))

# Open and read config file
with open(args.config) as config_file_open:
    config_contents = list(filter(None, config_file_open.read().split('\n')))

#print headers
print ("SNP\tchromosome\tposition\tpvalue\tcategory\tcolor_category\tlength")

# Iterate over each line in contents and config_contents
for line in contents:
    if len(line) < 2:
         pass
    else:
        line_t = list(filter(None, line.split('\t')))
        if len(line_t) < 2:
             pass
        else:
            chr_name, chr_pos, marker_name, p_value = line_t[:4]  # Ensure line_t has at least 4 items

            for con in config_contents:
                con_t = con.split('\t')
                o_name, c_name, con_len, con_type, con_color = con_t[:5]  # Ensure con_t has at least 4 items

                if chr_name == o_name:
                    print(marker_name, o_name, chr_pos, p_value, con_type, con_color, con_len, sep="\t")
