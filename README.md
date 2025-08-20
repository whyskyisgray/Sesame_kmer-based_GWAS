# Sesame_kmer-based_GWAS workflow


Requirements
------------
- Shell: zsh
- Parallelization: GNU parallel
- Container runtime: Singularity
- Software:
  - KMC (via `KMC_count_kmer-imcrop4.zsh`, https://github.com/refresh-bio/KMC)
  - kmersGWAS (https://github.com/voichek/kmersGWAS)

Folder Layout & Inputs
----------------------
- Working directory: Parent folder with one subdirectory per sample.
- Phenotype table: `kmer_pheno_merge.mod.tsv` with `accession_id` as the first column and trait columns from the second onward.


Example header:
```
accession_id   TraitA   TraitB   TraitC
```


1. Make the sample directory list
```
ls -d */ | while read line; do realpath $line; done > sample_dir.txt
```

2. Run KMC in parallel
```
cat sample_dir.txt | while read line; do
  echo "zsh $code_dir/kmers_gwas/KMC_count_kmer-imcrop4.zsh 31 2 2 $line"
done | parallel -j 60
```

3. Build the k-mer list paths
```
find $(pwd) | grep 'kmers_with_strand$' | while read line; do
  file_name=$(basename $line)
  echo -e "$line	$file_name"
done > kmers_list_paths.txt
```

4. Filter shared k-mers
```
singularity run $SIF /app/bin/list_kmers_found_in_multiple_samples   -l kmers_list_paths.txt -k 31 --mac 3 -p 0.2 -o kmers_to_use   1> listkmers.log 2> listkmers.err
```

5. Build the k-mer table
```
singularity run $SIF /app/bin/build_kmers_table   -l kmers_list_paths.txt -k 31 -a kmers_to_use -o kmers_table   1> kmertable.log 2> kmertable.err
```

6. Generate phenotype files
```
pheno=$(realpath kmer_pheno_merge.mod.tsv)
col_number=$(head -1 $pheno | tr '	' '
' | wc -l)
for i in $(seq 2 $col_number); do
  ids=$(head -1 $pheno | cut -f $i)
  echo -e "accession_id	phenotype_value" > $ids.pheno
  cut -f 1,$i $pheno | awk '{print $1"_kmers_with_strand	"$2}' | grep -v Taxa >> $ids.pheno
done
```

7. Prepare the run manifest
```
ls *.pheno | while read f; do
  base=${f%.pheno}
  echo "$base $(realpath $f)"
done > running_file
```

8. run kmerGWAS program
```
cat $running_file| while read ids paths
do
  echo "python2.7 $programs/kmersGWAS_docker/kmers_gwas.py \
  --pheno $paths \
  --kmers_table kmers_table \
  --gemma_path $programs/gemma_0_98/gemma_0_98 \
  --outdir $ids \
  -l 31 \
  -p 10 \
  -k 100000 \
  --maf 0.01"
done | parallel -j 4
```


