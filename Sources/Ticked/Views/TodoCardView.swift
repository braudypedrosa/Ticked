import EfficiencyCore
import SwiftUI

struct TodoCardView: View {
    let todo: TodoItem
    let toggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(todo.provider.displayName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button(action: toggle) {
                    Image(systemName: todo.isLocallyCompleted ? "checkmark.circle.fill" : "circle")
                }
                .buttonStyle(.plain)
                .help(todo.isLocallyCompleted ? "Mark open" : "Mark complete")
            }

            Text(todo.title)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 8)

            VStack(alignment: .leading, spacing: 4) {
                if let sourceName = todo.sourceName {
                    Label(sourceName, systemImage: "folder")
                }
                if let dueDate = todo.dueDate {
                    Label(dueDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(minHeight: 150, alignment: .topLeading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

