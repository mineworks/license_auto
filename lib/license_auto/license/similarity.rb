require 'tf-idf-similarity'
require 'license_auto/license/frequency'


class Similarity
  # If text is too long to index, skip it?
  MAX_TEXT_LENGTH = 20000

  # Similarity ratio
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
      LicenseAuto.logger.warn("License file not exist: #{abs_filename_path} !")
      nil
    end
  end

  def most_sim_license
    license_file_index = @license_template_documents.count - 1
    sim_ratios = @license_template_documents[0..(license_file_index -1)].map.with_index { |doc, index|
      ratio = @matrix[license_file_index, index]
    }
    # LicenseAuto.logger.debug(sim_ratios)
    sim_license_index = sim_ratios.index(sim_ratios.max)

    LICENSE_SORTED_FREQUENCY[sim_license_index]
  end
end
