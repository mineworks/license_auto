require 'httparty'
require_relative '../conf/config'
require_relative '../lib/message'

def add_product(product_name)
  r = $conn.exec_params("select * from product where name = $1", [product_name])
  if r.ntuples == 1
    return false, r[0]
  else
    product = $conn.exec_params("insert into product (name) select $1 returning *", [product_name])
    if product.ntuples == 1
      return true, product[0]
    end
  end
end

def add_repo(repo_name, source_url, parent_repo_id=nil, priv=-1)
  r = $conn.exec_params("select * from product where name = $1", [repo_name])
  if r.ntuples == 1
    return false, r[0]
  else
    repo = $conn.exec_params("insert into repo (name, source_url, priv, parent_repo_id) select $1, $2, $3, $4 returning *",
                             [repo_name, source_url, priv, parent_repo_id])
    if repo.ntuples == 1
      return true, repo[0]
    end
  end
end

def api_get_repo_source_url(repo_id)
  source_url = nil
  r = $conn.exec_params("select source_url from repo where id = $1", [repo_id])
  if r.ntuples == 1
     source_url = r[0]['source_url']
  end

  source_url
end

def api_clear_relations(release_id, repo_id)
  r = $conn.exec_params("
        delete from product_repo_pack
          where product_repo_id in (
            select id from product_repo where
              release_id = $1
              and repo_id = $2
          )", [release_id, repo_id])
  $plog.warn("You are rerunning the repo's deps, the history relation table data of this repo was deleted")
end

def api_get_case_by_id(case_id)
  repo_id = nil
  r = $conn.exec_params("select product_id, release_id, repo_id from product_repo where id = $1", [case_id])
  if r.ntuples == 1
    repo_id = r[0]
  end
  repo_id
end

def api_query_product_repo(release_id, repo_id)
  r = $conn.exec_params("
        select * from product_repo
          where release_id = $1
          and repo_id = $2", [release_id, repo_id])
end

def api_get_repo_manifest_file_list(repo_id)
  r = $conn.exec_params("select ymls from repo where id = $1", [repo_id])
end

def api_add_product_repo(release_id, parent_repo_id, sub_repo_id)
  $plog.debug("release_id: #{release_id}, parent_repo_id: #{parent_repo_id}")
  all_products = $conn.exec_params("
    select * from product_repo
      where release_id = $1
      and repo_id = $2", [release_id, parent_repo_id])
  all_products.each {|p|
    product_id = p['product_id']
    $plog.debug("product_id: #{product_id}")
    begin
      r = $conn.exec_params("insert into product_repo (release_id, product_id, repo_id) values ($1, $2, $3)",
                          [release_id, product_id, sub_repo_id])
    rescue Exception => e
      $plog.fatal(e)
    end
  }

end

def api_add_product_repo_pack(repo_id, pack_id, release_id)
  # $plog.debug("api_add_product_repo_pack: (repo_id=#{repo_id}, pack_id=#{pack_id}, release_id=#{release_id})")
  r = $conn.exec_params("select add_product_repo_pack($1, $2, $3)", [repo_id, pack_id, release_id])
  # $plog.debug("SQL: select add_product_repo_pack(#{repo_id}, #{pack_id}, #{release_id})")
  r[0]
end

def api_add_pack(pack_name, pack_version, lang, homepage, source_url, license, status, cmt)
  # "select * from select add_pack('goose', 'unknown', 'Golang', null, null, null, null, null) as t(pack_id integer, new bool)"
  # $plog.info("status: #{status}")
  r = $conn.exec_params("select * from add_pack($1, $2, $3, $4, $5, $6, $7, $8) as t(pack_id integer, is_newbie bool)",
                        [pack_name, pack_version, lang, homepage, source_url, license, status, cmt])
  ret = nil
  if r.ntuples == 1
    ret = r[0]
  end
  ret
end

def api_get_complete_ratio(release_id, repo_id)
  # TODO: port
  ratio = 0.0
  api_path = '/api/v1/repo/complete_ratio'
  api_url = "#{LICENSE_WEBSITE_URL}#{api_path}"
  response = HTTParty.get(api_url,
                          :query => {
                            :release_id => release_id,
                            :repo_id => repo_id
                          })
  if response.code == 200
    ratio = response.body.to_f
    $plog.debug("complete_ratio: #{ratio}")
    if ratio >= 0.95
      release_name = nil
      repo_source_url = nil
      content = "Your release: #{release_name}, repo: #{repo_source_url} has completed, check it please."
      Message.send(content)
    end
  else
    $plog.error("#{response}")
  end
  ratio
end

def api_get_pack_by_id(pack_id)
  pack = nil
  r = $conn.exec_params("select id, name, version, source_url, lang, homepage, license, license_text, status from pack
                           where id = $1", [pack_id])
  if r.ntuples == 1
    pack = r[0]
  end
  pack
end

def api_get_std_license_name(where='where 1 = 1')
  r = $conn.exec("select * from std_license #{where}")
end

def api_setup_pack_status(pack_id, status, cmt)
  $plog.debug(cmt)
  r = $conn.exec_params("update pack set status = $1, cmt = $2, update_at = now() where id = $3", [status, cmt[0..79], pack_id])
end

def api_setup_case_status(repo_id, status, cmt)
  $plog.debug(cmt)
  r = $conn.exec_params("update product_repo set status = $1, cmt = $2, update_at = now() where id = $3", [status, cmt[0..79], repo_id])
end


def api_update_pack_info(pack_id, pack)
  # r = $conn.exec_params("select update_pack($1,$2,$3,$4,$5,$6,$7,$8,$9)",[pack_id,pack['version'],pack['homepage'],pack['source_url'],pack['license_url'],pack['license'],pack['unclear_license'],pack['license_text'],pack['status']])


  r = $conn.exec_params("select update_pack($1,$2,$3,$4,$5,$6,$7,$8,$9)",
                        [pack_id, pack[:version], pack[:homepage], pack[:source_url], pack[:license_url],
                         pack[:license], pack[:unclear_license], pack[:license_text], pack[:status]])
  if(r[0] == -1)
    return false
  else
    return true
  end
end

def api_get_packs_by_name(name, version, lang)
  r = $conn.exec_params("select * from pack where name = $1 and version = $2 and lang = $3",[name, version, lang])
  return r
end

def api_get_gemdata_by_name(name)
  r = $gemconn.exec_params("select rubygems.name, versions.number, linksets.home, linksets.code, versions.licenses 
                              from rubygems, versions, linksets 
                              where rubygems.id = versions.rubygem_id 
                              and rubygems.id = linksets.rubygem_id 
                              and rubygems.name = $1 
                              and versions.latest = true 
                              and versions.platform = $2", [name, 'ruby'])
end

def api_get_gemdata_by_name_and_version(name, version)
  r = $gemconn.exec_params("select rubygems.name, versions.number, linksets.home, linksets.code, versions.licenses 
                              from rubygems, versions, linksets 
                              where rubygems.id = versions.rubygem_id 
                              and rubygems.id = linksets.rubygem_id 
                              and rubygems.name = $1 
                              and versions.number = $2", [name, version])
end

def api_get_template_result_by_product(name, release_name, release_version)
  list = nil
  r = $conn.exec_params("select product.name, repo.name, pack.name, pack.version, pack.unclear_license, pack.license, pack.license_text, pack.source_url 
                            from product_repo_pack 
                            join pack on product_repo_pack.pack_id = pack.id 
                            join product_repo on product_repo_pack.product_repo_id = product_repo.id 
                            join repo on product_repo.repo_id = repo.id 
                            join product on product_repo.product_id = product.id 
                            join release_tbl on product_repo.release_id = release_tbl.id 
                            where product.name = $1 
                            and release_tbl.name = $2 
                            and release_tbl.version = $3", [name, release_name, release_version])
  if r.ntuples > 0
    list = r
  end
  list
end

def api_get_repo_list_by_product(name, release_name, release_version)
  repo_list = nil
  r = $conn.exec_params("select product_repo.id, repo.name 
                            from product_repo 
                            join product on product_repo.product_id = product.id 
                            join repo on product_repo.repo_id = repo.id 
                            join release_tbl on product_repo.release_id = release_tbl.id 
                            where product.name = $1 
                            and release_tbl.name = $2 
                            and release_tbl.version = $3", [name, release_name, release_version])
  if r.ntuples > 0
    repo_list = r
  end
  repo_list
end

def api_get_template_result_by_product_repo_id(id)
  list = nil
  r = $conn.exec_params("select pack.name, pack.version, pack.unclear_license, pack.license, pack.license_text, pack.source_url 
                            from product_repo_pack 
                            join pack on product_repo_pack.pack_id = pack.id 
                            where product_repo_pack.product_repo_id = $1", [id])
  if r.ntuples > 0
    list = r
  end
  list
end

def api_get_manifest_download_url(pack_id)
  r = $conn.exec_params("select source_url from pack where id = $1", [pack_id])
end

# org_url: github.com/your_org_or_person_name
def api_get_whitelist_orgs(org_url)
  r = $conn.exec_params("select * from whitelist_orgs where url = $1", [org_url])
end

def api_get_repo_by_url(url)
  r = $conn.exec_params("select * from repo where source_url = $1", [url])
end

if __FILE__ == $0
  # p api_get_repo_manifest_file_list(80).values[0]
  api_get_complete_ratio(1, 2)
end