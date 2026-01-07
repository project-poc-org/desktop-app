import tkinter as tk
import os

# OpenTelemetry setup
from opentelemetry import trace
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter

VERSION = os.getenv("DESKTOP_VERSION", "dev")

# Instrumentation
resource = Resource(attributes={"service.name": "desktop-app", "service.version": VERSION})
trace.set_tracer_provider(TracerProvider(resource=resource))
otlp_exporter = OTLPSpanExporter(
    endpoint=os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT", "http://localhost:4318/v1/traces"),
)
span_processor = BatchSpanProcessor(otlp_exporter)
trace.get_tracer_provider().add_span_processor(span_processor)
tracer = trace.get_tracer(__name__)

with tracer.start_as_current_span("desktop_app_main"):
	root = tk.Tk()
	root.title(f"Sample Desktop App v{VERSION}")
	label = tk.Label(root, text=f"Hello from Python Desktop App! Version: {VERSION}")
	label.pack(padx=20, pady=20)
	root.mainloop()
