{ fetchgit, ... }:
{
  assets = fetchgit {
    url = "https://github.com/bailey-busc/lfs";
    branchName = "main";
    sha256 = "sha256-q2XwlfjzCFK4P5w2oVDaidK5pTua4BOu3ZaYW5VNmpc=";
    fetchLFS = true;
  };
}
