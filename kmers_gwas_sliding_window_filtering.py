import pandas as pd
import numpy as np
import argparse

def filter_snps(input_file, output_file, window_size, min_depth, log_pvalue_threshold):
    # Load the data into a DataFrame
    df = pd.read_csv(input_file, sep='\t')
    
    # Calculate log of pvalue
    df['log_pvalue'] = -np.log10(df['pvalue'])
    
    # Initialize a list to store results
    results = []

    # Iterate over chromosomes
    for chrom in df['chromosome'].unique():
        # Filter data for the current chromosome
        chrom_df = df[df['chromosome'] == chrom].sort_values(by='position')
        
        # Iterate over positions
        for i, row in chrom_df.iterrows():
            start_pos = row['position']
            end_pos = start_pos + window_size - 1
            
            # Find SNPs within the window
            window_df = chrom_df[(chrom_df['position'] >= start_pos) & (chrom_df['position'] <= end_pos)]
            
            # Check if there are SNPs with log_pvalue >= log_pvalue_threshold and depth >= min_depth
            high_logp_df = window_df[window_df['log_pvalue'] >= log_pvalue_threshold]
            if len(high_logp_df) >= min_depth:
                results.append(window_df)

    # Concatenate results into a DataFrame and remove duplicates
    result_df = pd.concat(results).drop_duplicates(subset=['SNP', 'chromosome', 'position', 'pvalue', 'category', 'color_category', 'length'])
    
    # Drop the log_pvalue column
    result_df = result_df.drop(columns=['log_pvalue'])
    
    # Save the results to the output file
    result_df.to_csv(output_file, sep='\t', index=False)
    
    # Print the number of lines that were not filtered out
    print(f"{len(result_df)} variations are saved to {output_file}")

def main():
    # Set up argparse
    parser = argparse.ArgumentParser(description='Filter SNPs based on conditions')
    parser.add_argument('-i', '--input', required=True, help='Input file path')
    parser.add_argument('-o', '--output', required=True, help='Output file path')
    parser.add_argument('-w', '--window_size', type=int, required=True, help='Window size')
    parser.add_argument('-d', '--depth', type=int, required=True, help='Minimum depth for SNPs with log_pvalue >= log_pvalue_threshold')
    parser.add_argument('-lp', '--log_pvalue', type=float, required=True, help='Log P value threshold')
    
    # Parse arguments
    args = parser.parse_args()
    
    # Run the function
    filter_snps(args.input, args.output, args.window_size, args.depth, args.log_pvalue)

if __name__ == "__main__":
    main()

