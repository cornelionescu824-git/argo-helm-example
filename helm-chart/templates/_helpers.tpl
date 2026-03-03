{{/*
Expand the name of the chart.
*/}}
{{- define "simple-api.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}
