{ pkgs, hostname, selfSourceInfo }:
let
  # fails if the source tree is not clean, i.e. uncommitted changes
  shortRev = assert selfSourceInfo ? shortRev ; selfSourceInfo.shortRev;
  thisRepoURI = "github:jali-clarke/homelab-config";

  # %Y%m%d%H%M%S
  lastModifiedDate = selfSourceInfo.lastModifiedDate;
  lastModifiedYear = builtins.substring 0 4 lastModifiedDate;
  lastModifiedMonth = builtins.substring 4 2 lastModifiedDate;
  lastModifiedDay = builtins.substring 6 2 lastModifiedDate;
  lastModifiedHour = builtins.substring 8 2 lastModifiedDate;
  lastModifiedMinute = builtins.substring 10 2 lastModifiedDate;
  lastModifiedSecond = builtins.substring 12 2 lastModifiedDate;
in
{
  versionedFlakeURI = "${thisRepoURI}/${shortRev}#${hostname}";
  lastModifiedFormatted = "${lastModifiedYear}-${lastModifiedMonth}-${lastModifiedDay} ${lastModifiedHour}:${lastModifiedMinute}:${lastModifiedSecond} UTC";
}
