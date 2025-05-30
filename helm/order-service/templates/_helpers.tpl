
{{- define "order-service.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "order-service.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "order-service.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "order-service.labels" -}}
helm.sh/chart: {{ include "order-service.chart" . }}
{{ include "order-service.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "order-service.selectorLabels" -}}
app.kubernetes.io/name: {{ include "order-service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "order-service.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{- default (include "order-service.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
    {{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/*
Helper function: order-service.util.drzew (Default if Local is nil/not boolean, Else use local, fallback to Global, then to ultimate Default)
Used to determine if a feature (like database, cloudsqlproxy, rabbitmq) is enabled.
It expects a list of three arguments:
1. The local .Values.<feature>.enabled value.
2. The global .Values.global.<feature>.enabled value.
3. An ultimate default boolean value (e.g., true or false) if neither local nor global is a valid boolean.
*/}}
{{- define "order-service.util.drzew" -}}
{{- $localEnabled := first . -}}
{{- $globalEnabled := index . 1 -}}
{{- $ultimateDefault := index . 2 | default false -}} {{/* Default cuối cùng là false nếu không có gì khác */}}

{{- $chosenValue := $ultimateDefault -}} {{/* Khởi tạo với default cuối cùng */}}

{{- if kindIs "bool" $globalEnabled -}}
  {{- $chosenValue = $globalEnabled -}} {{/* Ưu tiên global nếu nó là bool */}}
{{- end -}}

{{- if kindIs "bool" $localEnabled -}}
  {{- $chosenValue = $localEnabled -}} {{/* Ghi đè bằng local nếu nó là bool */}}
{{- end -}}

{{- $chosenValue -}}
{{- end -}}
