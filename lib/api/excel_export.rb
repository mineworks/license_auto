require 'json'
require 'writeexcel'

module API

  class ExcelExport
    require_relative '../db'
    def initialize
      #TODO
    end

    def get_excel_by_product(name, release_name, release_version)
      #name -> productName
      #release_name -> 'foo'
      #release_version -> '1.5'
      workbook_name = name + '-1.5-scotzilla-script.xls'

      #get the repo list
      repolist = api_get_repo_list_by_product(name, release_name, release_version)

      if repolist == nil
        return false
      end

      # Create a new workbook and add a worksheet
      workbook  = WriteExcel.new(workbook_name)

      set_validation_worksheet(workbook)
      #  list {id->product_repo.id, name->repo.name}

      set_repolist_worksheet(workbook, repolist)

      workbook.close

      return true

    end

    def set_repolist_worksheet(workbook, repolist)

      # Create a format for the column headings
      header = workbook.add_format
      header.set_bold
      header.set_size(12)
      header.set_color('black')

      num = 0
      while num < repolist.ntuples() do
        # get pack list from db
        packlist = api_get_template_result_by_product_repo_id(repolist[num]['id'])

        unless packlist == nil
          worksheet = nil
          worksheet = workbook.add_worksheet(repolist[num]['name'])
          # Set the column width for columns 1 ~ 9
          worksheet.set_column(0, 4, 20)
          worksheet.set_column(5, 5, 40)
          worksheet.set_column(6, 6, 15)
          worksheet.set_column(7, 7, 35)
          worksheet.set_column(8, 8, 15)

          #modified_range = 'G2:G' + (packlist.ntuples() + 1)
          #interaction_range = 'H2:H' + (packlist.ntuples() + 1)

          # TODO: @Micfan, validation excle
          # Create a format for the column license
          worksheet.data_validation('D2:D21', {
            :validate => 'integer',
            :criteria => '>',
            :value    => 100,
            # :source => ['MIT', 'BSD', 'Apache2.0']
            # :source => '=Validation!$C$2:$C$16'
          })

          # Modified dropdown list
          # worksheet.data_validation('G2:G10',
          # {
          #   :validate => 'list',
          #   :source => '=Validation!$B$2:$B$3'
          #   #:source => ['No', 'Yes']
          #   })

          # worksheet.data_validation('H2:H400',
          # {
          #   :validate => 'list',
          #   :source => '=Validation!$A$2:$A$13'
          #   #:source => ['Distributed - Calling Existing Classes',
          #     #'Distributed - Deriving New Classes',
          #     #'Distributed - Dynamic Link w/ OSS',
          #     #'Distributed - Dynamic Link w/ TP',
          #     #'Distributed - Dynamic Link w/ VMW',
          #     #'Distributed - No Linking',
          #     #'Distributed - OS Layer',
          #     #'Distributed - Other',
          #     #'Distributed - Static Link w/ OSS',
          #     #'Distributed - Static Link w/ TP',
          #     #'Distributed - Static Link w/ VMW',
          #     #'Internal Use Only']
          #   })

          # Write pack list info in worksheet
          set_repo_worksheet(worksheet, packlist, header)
        end
        num = num + 1
        next
      end

    end

    def set_repo_worksheet(worksheet, packlist, header)

      j = 0
      # Write header data
      worksheet.write(j, 0, 'Name', header)
      worksheet.write(j, 1, 'Version', header)
      worksheet.write(j, 2, 'Description', header)
      worksheet.write(j, 3, 'License', header)
      worksheet.write(j, 4, 'License Text', header)
      worksheet.write(j, 5, 'URL', header)
      worksheet.write(j, 6, 'Modified', header)
      worksheet.write(j, 7, 'Interaction', header)
      worksheet.write(j, 8, 'OSS Project', header)

      # Write pack info list
      while j < packlist.ntuples() do
        worksheet.write(j+1, 0, packlist[j]['name'])
        worksheet.write(j+1, 1, packlist[j]['version'])
        worksheet.write(j+1, 2, packlist[j]['unclear_license'])
        worksheet.write(j+1, 3, packlist[j]['license'])
        #worksheet.write(j+1, 4, packlist[j]['license_text'])
        worksheet.write(j+1, 5, packlist[j]['source_url'])
        worksheet.write(j+1, 6, 'No')
        worksheet.write(j+1, 7, 'Distributed - Calling Existing Classes')
        worksheet.write(j+1, 8, '')
        j = j + 1
        next
      end

    end

    def set_validation_worksheet(workbook)

      worksheet = workbook.add_worksheet('Validation')
      worksheet.set_column(0, 2, 30)

      # define the header format
      header = workbook.add_format
      header.set_bold
      header.set_size(10)
      header.set_color('black')

      # Write Data
      #header
      worksheet.write(0, 0, 'InteractionTypes', header)
      worksheet.write(0, 1, 'ModificationOptions', header)
      worksheet.write(0, 2, 'LicenseChoices', header)

      #InteractionTypes
      worksheet.write(1, 0, 'Distributed - Calling Existing Classes')
      worksheet.write(2, 0, 'Distributed - Deriving New Classes')
      worksheet.write(3, 0, 'Distributed - Dynamic Link w/ OSS')
      worksheet.write(4, 0, 'Distributed - Dynamic Link w/ TP')
      worksheet.write(5, 0, 'Distributed - Dynamic Link w/ VMW')
      worksheet.write(6, 0, 'Distributed - No Linking')
      worksheet.write(7, 0, 'Distributed - OS Layer')
      worksheet.write(8, 0, 'Distributed - Other')
      worksheet.write(9, 0, 'Distributed - Static Link w/ OSS')
      worksheet.write(10, 0, 'Distributed - Static Link w/ TP')
      worksheet.write(11, 0, 'Distributed - Static Link w/ VMW')
      worksheet.write(12, 0, 'Internal Use Only')
      
      #ModificationOptions
      worksheet.write(1, 1, 'No')
      worksheet.write(2, 1, 'Yes')
    
      #LicenseChoices
      licenses = api_get_std_license_name()
      num = 0
      while num < licenses.ntuples() do
        worksheet.write(num+1, 2, licenses[num]['name'])
        num = num + 1
        next
      end

    end

  end

end ### API
