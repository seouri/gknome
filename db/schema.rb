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

ActiveRecord::Schema.define(:version => 20110506051939) do

  create_table "results", :force => true do |t|
    t.integer "genome_id"
    t.string  "chromosome"
    t.string  "source"
    t.string  "var_type"
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
    t.string  "impact"
    t.string  "variant_seq_index"
    t.string  "gene_component"
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

  add_index "results", ["genome_id"], :name => "index_results_on_genome_id"
  add_index "results", ["impact"], :name => "index_results_on_impact"
  add_index "results", ["var_id"], :name => "index_results_on_var_id"
  add_index "results", ["var_type"], :name => "index_results_on_var_type"

end
