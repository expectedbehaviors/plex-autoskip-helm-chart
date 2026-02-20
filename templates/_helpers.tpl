{{- /*
  config.ini for PlexAutoSkip. Token placeholder __PLEX_TOKEN__ replaced by ExternalSecret template.
*/ -}}
{{- define "plex-autoskip.config_ini" -}}
{{- $c := .Values.skip.config | default dict }}
[Plex.tv]
username = 
password = 
token = __PLEX_TOKEN__
servername = {{ $c.servername | default "Plex" }}
[Server]
address = {{ $c.address | default "plex" }}
ssl = {{ $c.ssl | default false }}
port = {{ $c.port | default "32400" }}
[Security]
ignore-certs = {{ $c.ignoreCerts | default true }}
[Skip]
mode = {{ $c.mode | default "skip" }}
tags = {{ $c.tags | default "intro, commercial, advertisement, credits, outro, preview" }}
types = {{ $c.types | default "movie, episode" }}
ignored-libraries = {{ $c.ignoredLibraries | default "" }}
last-chapter = {{ $c.lastChapter | default "0.0" }}
unwatched = {{ $c.unwatched | default true }}
first-episode-series = {{ $c.firstEpisodeSeries | default "Watched" }}
first-episode-season = {{ $c.firstEpisodeSeason | default "Watched" }}
first-safe-tags = {{ $c.firstSafeTags | default "intro, credits" }}
last-episode-series = {{ $c.lastEpisodeSeries | default "Watched" }}
last-episode-season = {{ $c.lastEpisodeSeason | default "Watched" }}
last-safe-tags = {{ $c.lastSafeTags | default "outro, credits" }}
next = {{ $c.next | default true }}
[Binge]
ignore-skip-for = {{ $c.ignoreSkipFor | default 1 }}
safe-tags = {{ $c.safeTags | default "commercial, advertisement, preview" }}
same-show-only = {{ $c.sameShowOnly | default true }}
skip-next-max = {{ $c.skipNextMax | default 0 }}
[Offsets]
start = {{ $c.offsetStart | default 1000 }}
end = {{ $c.offsetEnd | default 1000 }}
command = {{ $c.offsetCommand | default 500 }}
tags = {{ $c.offsetTags | default "intro" }}
[Volume]
low = {{ $c.volumeLow | default 0 }}
high = {{ $c.volumeHigh | default 100 }}
{{- end -}}

{{- define "plex-autoskip.logging_ini" -}}
{{- $log := .Values.skip.logging | default dict }}
[loggers]
keys = root
[handlers]
keys = consoleHandler, fileHandler
[formatters]
keys = simpleFormatter, minimalFormatter
[logger_root]
level = {{ $log.rootLevel | default "DEBUG" }}
handlers = consoleHandler, fileHandler
[handler_consoleHandler]
class = StreamHandler
level = {{ $log.consoleLevel | default "INFO" }}
formatter = minimalFormatter
args = (sys.stdout,)
[handler_fileHandler]
class = handlers.RotatingFileHandler
level = {{ $log.fileLevel | default "INFO" }}
formatter = simpleFormatter
args = ('{{ $log.logFilename | default "activity.log" }}', 'a', {{ $log.fileMaxBytes | default 100000 }}, {{ $log.fileBackupCount | default 3 }}, 'utf-8')
[formatter_simpleFormatter]
format = %(asctime)s - %(name)s - %(levelname)s - %(message)s
datefmt = %Y-%m-%d %H:%M:%S
[formatter_minimalFormatter]
format = %(levelname)s - %(message)s
datefmt =
{{- end -}}

{{- define "plex-autoskip.custom_json" -}}
{{- if .Values.skip.customJson.raw }}
{{ tpl .Values.skip.customJson.raw . }}
{{- else }}
{"markers":{},"offsets":{},"tags":{},"allowed":{"users":[],"clients":[],"keys":[],"skip-next":[]},"blocked":{"users":[],"clients":[],"keys":[],"skip-next":[]},"clients":{},"mode":{}}
{{- end }}
{{- end -}}
