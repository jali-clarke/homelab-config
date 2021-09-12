{ pkgs, hostname, selfSourceInfo }:
let
  # fails if the source tree is not clean, i.e. uncommitted changes
  shortRev = assert selfSourceInfo ? shortRev ; selfSourceInfo.shortRev;

  thisRepoURI = "github:jali-clarke/homelab-config";
  lastModifiedDate = selfSourceInfo.lastModifiedDate;
in
{
  versionedFlakeURI = "${thisRepoURI}/${shortRev}#${hostname}";
  lastModifiedFormatted = lastModifiedDate;
}
