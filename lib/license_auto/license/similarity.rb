require 'matrix'
require 'tf-idf-similarity'
require 'license_auto/license/frequency'


class Similarity

  # Expected similarity ratio
  SIM_RATIO = 0.85

  def initialize(license_content)
    # LicenseAuto.logger.debug(license_content)
    @license_template_documents =
        LICENSE_SORTED_FREQUENCY.reject {|template_name|
          abs_filename_path(template_name).nil?
        }.map {|template_name|
          abs_file = abs_filename_path(template_name)
          TfIdfSimilarity::Document.new(File.read(abs_file))
        }.compact
    @license_template_documents.push(
        TfIdfSimilarity::Document.new(license_content)
    )
    model = TfIdfSimilarity::TfIdfModel.new(@license_template_documents)
    @matrix = model.similarity_matrix
    # LicenseAuto.logger.debug(@license_template_documents)
    # LicenseAuto.logger.debug(@matrix[0, 2])
  end

  def abs_filename_path(template_name)
    filename_path = "../templates/#{template_name}.txt"
    abs_filename_path = File.expand_path(filename_path, __FILE__)
    if FileTest.file?(abs_filename_path)
      abs_filename_path
    else
      LicenseAuto.logger.info("License file not exist: #{abs_filename_path} !")
      nil
    end
  end

  def most_license_sim
    license_file_index = @license_template_documents.count - 1
    sim_ratios = @license_template_documents[0..(license_file_index -1)].map.with_index { |doc, index|
      ratio_ = @matrix[license_file_index, index]
    }
    max_sim_ratio = sim_ratios.max
    sim_license_index = sim_ratios.index(max_sim_ratio)

    license_name = LICENSE_SORTED_FREQUENCY[sim_license_index]

    debug = "License: #{license_name}, Ratio: #{max_sim_ratio}"
    LicenseAuto.logger.debug(debug)

    [license_name, max_sim_ratio]
  end
end
