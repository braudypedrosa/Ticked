import EfficiencyCore
import SwiftUI

struct TodoRowView: View {
    let todo: TodoItem
    let toggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: toggle) {
                Image(systemName: todo.isLocallyCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .help(todo.isLocallyCompleted ? "Mark open" : "Mark complete")

            VStack(alignment: .leading, spacing: 5) {
                Text(todo.title)
                    .font(.body.weight(.medium))
                    .strikethrough(todo.isLocallyCompleted)
                HStack(spacing: 8) {
                    Text(todo.provider.displayName)
                    if let sourceName = todo.sourceName {
                        Text(sourceName)
                    }
                    if let dueDate = todo.dueDate {
                        Text(dueDate, style: .date)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }
}

