# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110507074550) do

  create_table "genomes", :force => true do |t|
    t.integer  "unique_variants"
    t.integer  "allele_frequency_common"
    t.integer  "allele_frequency_less_common"
    t.integer  "allele_frequency_rare"
    t.integer  "allele_frequency_novel"
    t.integer  "gene_component_3UTR"
    t.integer  "gene_component_5UTR"
    t.integer  "gene_component_CDS"
    t.integer  "gene_component_intergenic"
    t.integer  "gene_component_intron"
    t.integer  "gene_component_splice_site"
    t.integer  "impact_disrupt"
    t.integer  "impact_frameshift"
    t.integer  "impact_in_frame_deletion"
    t.integer  "impact_in_frame_insertion"
    t.integer  "impact_missense"
    t.integer  "impact_misstart"
    t.integer  "impact_nonsense"
    t.integer  "impact_nonstop"
    t.integer  "impact_synonymous"
    t.integer  "impact_unknown"
    t.integer  "varType_del"
    t.integer  "varType_ins"
    t.integer  "varType_snp"
    t.integer  "varType_sub"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "results", :force => true do |t|
    t.integer "genome_id",                    :limit => 2
    t.string  "chromosome",                   :limit => 5
    t.string  "source"
    t.string  "var_type",                     :limit => 3
    t.integer "var_begin"
    t.integer "var_end"
    t.string  "score"
    t.string  "var_strand"
    t.string  "phase"
    t.integer "var_id"
    t.string  "reference_seq"
    t.string  "variant_seq"
    t.string  "allele"
    t.float   "af_dbsnp132_eur"
    t.float   "af_1000g_eur"
    t.float   "af_200e_eur"
    t.string  "impact",                       :limit => 18
    t.string  "variant_seq_index"
    t.string  "gene_component",               :limit => 11
    t.string  "transcript_id"
    t.string  "gene_symbol"
    t.string  "transcript_position"
    t.string  "cds_position"
    t.string  "protein_position"
    t.string  "reference_codon"
    t.string  "variant_codon"
    t.string  "reference_amino_acid"
    t.string  "variant_amino_acid"
    t.float   "average_conservation_score"
    t.float   "portion_with_sequence_repeat"
    t.string  "sequence_repeat_detail"
    t.text    "conserved_tfbs"
    t.string  "mirna"
  end

  add_index "results", ["genome_id", "gene_component", "var_id"], :name => "index_results_on_genome_id_and_gene_component_and_var_id"
  add_index "results", ["genome_id", "impact", "af_dbsnp132_eur", "af_1000g_eur", "af_200e_eur", "gene_symbol"], :name => "index_results_on_genome_id_and_impact_and_af_and_gene_symbol"
  add_index "results", ["genome_id", "impact", "var_id"], :name => "index_results_on_genome_id_and_impact_and_var_id"
  add_index "results", ["genome_id", "var_id"], :name => "index_results_on_genome_id_and_var_id"
  add_index "results", ["genome_id", "var_type", "var_id"], :name => "index_results_on_genome_id_and_var_type_and_var_id"

end
